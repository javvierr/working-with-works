# frozen_string_literal: true

# New F3 validation guard adapted from the current reviewed F1 source.
# External selective copy only; never creates a database or changes app semantics.
# Reviewed against Active Record/Support 8.1.3 and pg 1.6.3.
require "json"
require "digest"
require "time"
require "pathname"

module F3Guard
  class Refusal < StandardError; end

  IDENTITY_SQL = <<~SQL.freeze
    SELECT current_database() AS database, current_user AS username,
           inet_server_addr()::text AS server_addr,
           inet_server_port() AS server_port, pg_backend_pid() AS backend_pid,
           current_setting('server_version_num') AS server_version_num,
           current_setting('data_directory') AS data_directory,
           current_setting('unix_socket_directories') AS socket_directory,
           current_setting('unix_socket_permissions') AS socket_permissions,
           current_setting('port') AS configured_port,
           current_setting('listen_addresses') AS listen_addresses
  SQL
  CLEANUP_SQL = /\A\s*(?:ROLLBACK(?:\s+(?:WORK|TRANSACTION))?(?:\s+TO(?:\s+SAVEPOINT)?\s+(?:"[A-Za-z0-9_]+"|[A-Za-z0-9_]+))?|ABORT(?:\s+(?:WORK|TRANSACTION))?)\s*;?\s*\z/i
  SESSION_SETUP_SQL = /\A\s*(?:SET\b|SHOW\b|SELECT\b)/i
  FORBIDDEN_DATABASE_SQL = /\b(?:CREATE|DROP|ALTER)\s+DATABASE\b/i

  def self.read_target!
    descriptor = Pathname.new(ENV.fetch("F3_TARGET_JSON")).realpath
    raise Refusal, "Target descriptor must be external F3 scratch" unless descriptor.to_s.start_with?("/private/tmp/www_f3_")
    target = JSON.parse(File.read(descriptor))
    %w[database username host port data_directory].each do |key|
      raise Refusal, "Missing explicit target #{key}" if target[key].to_s.empty?
    end
    raise Refusal, "Target is not an F3 disposable name" unless target["database"].match?(/\Awww_f3_[a-z0-9_]+\z/)
    host = target.fetch("host")
    raise Refusal, "Target must be the new F3 private socket" unless host.start_with?("/private/tmp/www_f3_pg_") && host.end_with?("/socket")
    raise Refusal, "Target must identify the new F3 data directory" unless target["data_directory"].start_with?("/private/tmp/www_f3_pg_") && target["data_directory"].end_with?("/data")
    raise Refusal, "Socket and data directory belong to different instances" unless File.dirname(host) == File.dirname(target["data_directory"])
    instance_root = File.dirname(host)
    raise Refusal, "Noncanonical F3 instance path" unless instance_root.match?(%r{\A/private/tmp/www_f3_pg_[a-z0-9_]+\z})
    raise Refusal, "Socket path must be canonical" unless File.realpath(host) == host
    raise Refusal, "Data path must be canonical" unless File.realpath(target["data_directory"]) == target["data_directory"]
    raise Refusal, "Socket directory is not private" unless File.directory?(host) && (File.stat(host).mode & 0o777) == 0o700
    raise Refusal, "Target data directory is missing" unless File.directory?(target["data_directory"])
    target["port"] = Integer(target.fetch("port"))
    raise Refusal, "Invalid target port" unless (1..65_535).cover?(target["port"])
    raise Refusal, "Target lacks new-creation declaration" unless target["newly_created"] == true
    evidence_path = target["creation_evidence"]
    raise Refusal, "Missing external creation evidence file" unless evidence_path.is_a?(String) && evidence_path.start_with?("/private/tmp/www_f3_") && File.file?(evidence_path)
    evidence = JSON.parse(File.read(evidence_path))
    raise Refusal, "Creation evidence database mismatch" unless evidence["database"] == target["database"]
    raise Refusal, "Creation evidence does not establish a new absent target" unless evidence["absent_before"] == true && evidence["created_by_this_run"] == true && evidence.dig("verified_empty", "application_relations") == 0
    recorded_identity = evidence.fetch("target_identity")
    Guard.validate_identity!(recorded_identity.merge("server_version_num" => recorded_identity["server_version_num"] || recorded_identity["version"]), target)
    target.freeze
  end

  def self.boot!
    %w[RAILS_ENV RACK_ENV].each { |key| raise Refusal, "#{key} must be test" unless ENV[key] == "test" }
    raise Refusal, "PARALLEL_WORKERS must be 1" unless ENV["PARALLEL_WORKERS"] == "1"
    raise Refusal, "Inherited primary/other database override" if ENV.keys.any? { |key| key.end_with?("_DATABASE_URL") }
    forbidden_pg = ENV.keys.select { |key| key.start_with?("PG") }
    raise Refusal, "Inherited PostgreSQL environment overrides" unless forbidden_pg.empty?
    raise Refusal, "DATABASE_URL must be explicit" if ENV["DATABASE_URL"].to_s.empty?
    raise Refusal, "Declared Ruby 4.0.5 required" unless RUBY_VERSION == "4.0.5"
    app_root = Pathname.new(ENV.fetch("F3_APP_ROOT")).realpath
    raise Refusal, "App must be an external F3 selective copy" unless app_root.to_s.start_with?("/private/tmp/www_f3_")
    raise Refusal, "Execution copy must not have Git metadata" if app_root.join(".git").exist?
    target = read_target!
    guard = Guard.new(target: target, event_path: ENV.fetch("F3_GUARD_LOG"))
    Dir.chdir(app_root)
    require app_root.join("config/application").to_s
    raise Refusal, "Reviewed Rails 8.1.3 required" unless Rails.version == "8.1.3"
    guard.install!
    guard.forbid_subprocesses!
    require app_root.join("config/environment").to_s
    raise Refusal, "Unexpected Rails root/environment" unless Rails.root.realpath == app_root && Rails.env.test?
    guard.verify_all!
    guard
  end

  class Guard
    attr_reader :target

    def initialize(target:, event_path:)
      @target = target
      @events = []
      @refusals = []
      @phase = "boot"
      @sequence = 0
      @identity_key = :"f3_guard_inside_identity_#{object_id}"
      log_path = Pathname.new(event_path)
      raise Refusal, "Guard evidence must be external F3 scratch" unless log_path.expand_path.to_s.start_with?("/private/tmp/www_f3_")
      @log = File.open(log_path, File::WRONLY | File::CREAT | File::EXCL, 0o600)
      @log.sync = true
    end

    def install!
      @subscription = ActiveSupport::Notifications.subscribe("sql.active_record", self)
      emit(kind: "guard_install", framework: ActiveRecord.version.to_s,
           ordering: "evented start executes before instrumented SQL block",
           identity_method: "private with_raw_connection materialize_transactions:false; PG exec SELECT only")
      self
    end

    def with_phase(label)
      previous = @phase
      @phase = label.to_s
      yield
    ensure
      @phase = previous
    end

    def set_phase!(label)
      @phase = label.to_s
    end

    def inside_identity?
      Thread.current[@identity_key] == true
    end

    def events_for(label)
      @events.select { |row| row[:phase] == label.to_s }
    end

    def emit(**fields)
      @sequence += 1
      row = { sequence: @sequence, at_utc: Time.now.utc.iso8601(6), phase: @phase }.merge(fields)
      @events << row
      @log.puts(JSON.generate(row))
      row
    end

    def refuse!(message)
      @refusals << message
      emit(kind: "refusal", outcome: "REFUSED", reason: message)
      raise Refusal, message
    end

    def ensure_no_refusals!
      raise Refusal, "Connection guard recorded #{@refusals.length} refusal(s)" unless @refusals.empty?
      true
    end

    def summary
      { events: @events.length, sql_events: @events.count { |r| r[:kind] == "sql" },
        cleanup_events: @events.count { |r| r[:kind] == "rollback_cleanup" },
        refusals: @refusals.dup, target: @target.slice("database", "username", "host", "port", "data_directory") }
    end

    def configuration!(db_config)
      refuse!("Missing adapter configuration") unless db_config
      config = db_config.configuration_hash
      safe = { "database" => config[:database], "username" => config[:username],
               "host" => config[:host], "port" => Integer(config.fetch(:port, 5432)),
               "adapter" => config[:adapter], "name" => db_config.name,
               "environment" => db_config.env_name }
      refuse!("Non-test/non-PostgreSQL connection") unless safe["environment"] == "test" && safe["adapter"] == "postgresql"
      %w[database username host port].each do |key|
        refuse!("Configured #{key} does not equal dedicated target") unless safe[key] == @target[key]
      end
      # A service or hostaddr could bypass the explicitly reviewed endpoint.
      refuse!("Unexpected libpq service/hostaddr override") if config[:service] || config[:servicefile] || config[:hostaddr]
      safe
    end

    def self.validate_identity!(observed, expected)
      %w[database username].each do |key|
        raise Refusal, "Server #{key} does not equal expected target" unless observed[key] == expected[key]
      end
      raise Refusal, "Server data directory differs from newly created instance" unless observed["data_directory"] == expected.fetch("data_directory")
      raise Refusal, "Server socket directory differs from new private endpoint" unless observed["socket_directory"] == expected.fetch("host")
      raise Refusal, "Server port setting mismatch" unless observed["configured_port"].to_i == expected.fetch("port")
      raise Refusal, "Server socket permissions must be 0700" unless observed["socket_permissions"] == "0700"
      raise Refusal, "TCP must remain disabled" unless observed["listen_addresses"] == ""
      raise Refusal, "User-authorized PostgreSQL 14.23 required" unless observed["server_version_num"].to_s == "140023"
      if expected.fetch("host").start_with?("/")
        raise Refusal, "Expected local socket, got TCP server identity" unless observed["server_addr"].nil? && observed["server_port"].nil?
      else
        raise Refusal, "Server address does not equal explicit loopback target" unless observed["server_addr"] == expected["host"]
        raise Refusal, "Server port mismatch" unless observed["server_port"].to_i == expected["port"]
      end
      true
    end

    def self.guarded_callback!(observed:, expected:)
      validate_identity!(observed, expected)
      yield
    end

    def live_identity!(adapter)
      configuration!(adapter.pool.db_config)
      previous = Thread.current[@identity_key]
      Thread.current[@identity_key] = true
      # This installed private method avoids SELECT materializing an outer lazy
      # transaction/BEGIN and avoids public raw_connection's dirty-state change.
      # Only our read-only, transaction-agnostic identity query uses the handle.
      identity = adapter.send(:with_raw_connection, allow_retry: false, materialize_transactions: false) do |raw|
        refuse!("Non-cleanup query attempted while transaction aborted") if raw.transaction_status == PG::PQTRANS_INERROR
        result = raw.exec(IDENTITY_SQL)
        begin
          result.first
        ensure
          result.clear
        end
      end
      self.class.validate_identity!(identity, @target)
      identity
    rescue Refusal => error
      # Pure/live deliberate controls invoke the comparator separately; real
      # mismatches here are always recorded and invalidate the diagnostic.
      refuse!(error.message) unless @refusals.last == error.message
      raise
    ensure
      Thread.current[@identity_key] = previous
    end

    def assert_connection!(adapter, phase: nil)
      action = lambda do
        identity = live_identity!(adapter)
        emit(kind: "explicit_identity", configuration: configuration!(adapter.pool.db_config),
             identity: identity, outcome: "PASS")
        identity
      end
      phase ? with_phase(phase, &action) : action.call
    end

    def verify_all!
      configs = ActiveRecord::Base.configurations.configs_for(env_name: "test", include_hidden: true)
      refuse!("No test database configuration") if configs.empty?
      configs.each { |config| configuration!(config) }
      pools = ActiveRecord::Base.connection_handler.connection_pool_list(:all)
      refuse!("No reachable database pools") if pools.empty?
      pools.each do |pool|
        configuration!(pool.db_config)
        pool.with_connection do |adapter|
          identity = live_identity!(adapter)
          emit(kind: "pool_identity", role: pool.role.to_s, shard: pool.shard.to_s,
               configuration: configuration!(pool.db_config), identity: identity, outcome: "PASS")
        end
      end
      true
    end

    # ActiveSupport's evented subscriber start runs before AbstractAdapter's
    # raw_execute SQL block. Raising here prevents that SQL from executing.
    def start(_name, _id, payload)
      adapter = payload.fetch(:connection) { refuse!("SQL event without adapter") }
      config = configuration!(adapter.pool.db_config)
      sql = payload.fetch(:sql).to_s
      refuse!("Database lifecycle SQL is outside guarded app operations") if sql.match?(FORBIDDEN_DATABASE_SQL)
      if inside_identity?
        # Connecting a new adapter can issue normal session/type-map SELECTs or
        # SETs. Never permit domain DML/DDL to hide behind the recursion guard.
        refuse!("Unexpected nested domain SQL during identity check") unless sql.match?(SESSION_SETUP_SQL)
        emit(kind: "connection_initialization", sql: sql, sql_sha256: Digest::SHA256.hexdigest(sql),
             configuration: config, identity: nil, outcome: "CONFIG_VERIFIED")
        return
      end
      if sql.match?(CLEANUP_SQL)
        # In particular: do NOT SELECT, call raw_connection, or verify/reconnect
        # here. An aborted transaction must reach its original Rails ROLLBACK.
        event = emit(kind: "rollback_cleanup", sql: sql, sql_sha256: Digest::SHA256.hexdigest(sql),
                     configuration: config, identity: nil, cached: !!payload[:cached], outcome: "CONFIG_ONLY_CLEANUP")
      else
        identity = live_identity!(adapter)
        event = emit(kind: "sql", sql: sql, sql_sha256: Digest::SHA256.hexdigest(sql),
                     configuration: config, identity: identity, cached: !!payload[:cached], outcome: "GUARDED_BEFORE_SQL")
      end
      payload[:f3_guard_sequence] = event.fetch(:sequence)
    end

    def finish(_name, _id, payload)
      return unless payload[:f3_guard_sequence]
      error_class = payload[:exception]&.first
      emit(kind: "sql_finish", start_sequence: payload[:f3_guard_sequence],
           outcome: error_class ? "SQL_ERROR" : "SQL_COMPLETE", exception_class: error_class,
           row_count: payload[:row_count])
    end

    def forbid_subprocesses!
      guarded_classes = [Kernel, Kernel.singleton_class, Process.singleton_class, IO.singleton_class]
      guarded_names = %i[system exec spawn fork popen] + [:"`"]
      @process_trace = TracePoint.new(:call, :c_call) do |trace|
        if guarded_names.include?(trace.method_id) && guarded_classes.include?(trace.defined_class)
          refuse!("Subprocess execution refused by single-process harness")
        end
      end
      @process_trace.enable
      emit(kind: "subprocess_guard", outcome: "INSTALLED")
    end

    def run_negative_controls!
      observed = nil
      ActiveRecord::Base.connection_pool.with_connection { |adapter| observed = live_identity!(adapter) }
      callbacks = 0
      synthetic = observed.merge("database" => "www_f3_synthetic_wrong_identity")
      pure_refused = false
      begin
        self.class.guarded_callback!(observed: synthetic, expected: @target) { callbacks += 1 }
      rescue Refusal
        pure_refused = true
      end
      wrong_expected = @target.merge("database" => "www_f3_deliberately_wrong_expected_identity")
      connected_refused = false
      begin
        self.class.guarded_callback!(observed: observed, expected: wrong_expected) { callbacks += 1 }
      rescue Refusal
        connected_refused = true
      end
      refuse!("Negative control did not refuse before callback") unless pure_refused && connected_refused && callbacks.zero?
      result = { pure_wrong_identity: "REFUSED", live_wrong_expected_identity: "REFUSED",
                 write_callback_calls: callbacks, dedicated_live_identity: observed }
      emit(kind: "deliberate_wrong_identity_controls", outcome: "PASS", **result)
      result
    end

    def schema_current!
      require "active_record/tasks/database_tasks"
      verify_all!
      configs = ActiveRecord::Base.configurations.configs_for(env_name: "test", include_hidden: true)
      configs.each do |config|
        refuse!("Schema is stale; automatic prepare/purge prohibited") unless ActiveRecord::Tasks::DatabaseTasks.schema_up_to_date?(config)
      end
      ActiveRecord::Migration.check_all_pending!
      emit(kind: "schema_current", outcome: "PASS", schema_sha256: Digest::SHA256.file(Rails.root.join("db/schema.rb")).hexdigest)
      true
    end
  end
end
