# frozen_string_literal: true
require_relative "f2_guard"

module F2Validation
  MIGRATION_VERSION = 20260919233000

  def self.migrate!(guard)
    baseline = Pathname.new(ENV.fetch("F2_BASELINE_SCHEMA")).realpath
    guard.refuse!("Baseline schema must be reviewed external F2 scratch") unless baseline.to_s.start_with?("/private/tmp/www_f2_")
    guard.refuse!("Baseline schema hash mismatch") unless Digest::SHA256.file(baseline).hexdigest == ENV.fetch("F2_BASELINE_SCHEMA_SHA256")
    require "active_record/tasks/database_tasks"
    pool = ActiveRecord::Base.connection_pool
    guard.verify_all!
    guard.refuse!("Target is not at the verified F1 baseline schema") unless ActiveRecord::Tasks::DatabaseTasks.schema_up_to_date?(pool.db_config, nil, baseline.to_s)
    context = pool.migration_context
    applied = context.get_all_versions
    pending = context.migrations.reject { |migration| applied.include?(migration.version) }.map(&:version)
    guard.refuse!("Only the additive F2 migration may run") unless pending == [MIGRATION_VERSION]
    guard.with_phase("f2_additive_migration") { context.migrate(MIGRATION_VERSION) }
    guard.with_phase("observed_schema_dump") do
      require "active_record/schema_dumper"
      schema = Rails.root.join("db/schema.rb")
      File.open(schema, "w:utf-8") { |file| ActiveRecord::SchemaDumper.dump(pool, file) }
      pool.internal_metadata.create_table_and_set_flags("test", Digest::SHA1.file(schema).hexdigest)
    end
    guard.schema_current!
    guard.ensure_no_refusals!
    { status: "PASS", operation: "f2_additive_migration", applied_version: MIGRATION_VERSION,
      schema_sha256: Digest::SHA256.file(Rails.root.join("db/schema.rb")).hexdigest, guard: guard.summary }
  end

  def self.run(operation)
    case operation
    when "suite"
      load File.expand_path("f2_suite.rb", __dir__)
    when "source-api"
      load File.expand_path("f2_source_api_check.rb", __dir__)
    else
      guard = F2Guard.boot!
      result = if operation == "migrate"
        migrate!(guard)
      else
        guard.schema_current!
        guard.with_phase("eager_load") { Rails.application.eager_load! }
        guard.ensure_no_refusals!
        { status: "PASS", operation: "verify", guard: guard.summary }
      end
      puts JSON.pretty_generate(result)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  operation = ARGV.shift
  unless %w[verify migrate suite source-api].include?(operation)
    puts <<~HELP
      F2 isolated validation: ruby script/final_submission/f2_validate.rb OPERATION
      Operations: verify, migrate, suite, source-api.
      Run from a verified external selective F2 application copy.
      Required: RAILS_ENV=test RACK_ENV=test PARALLEL_WORKERS=1, explicit DATABASE_URL,
      F2_APP_ROOT, F2_TARGET_JSON, F2_GUARD_LOG. Remove inherited PG and *_DATABASE_URL overrides.
      Target evidence must establish a separately created, initially empty database
      on a NEW private F2 PostgreSQL14.23 socket-only instance. A descriptor alone
      is not permission to adopt a database or reuse the retained F1 instance.
      migrate requires F2_BASELINE_SCHEMA and F2_BASELINE_SCHEMA_SHA256.
      suite requires F2_SUITE_RESULT_JSON and uses fixed seed 190926, one worker.
      source-api requires explicitly pinned external oracle/input/output paths;
      inspect the adjacent source/API script for its full evidence interface.
      This runner creates/starts/drops no database/service, installs nothing,
      does not seed/replant/clear, and never invokes original setup or CI.
      Retain logs, failed attempts and data; stop only the run-owned F2 instance.
    HELP
    exit(operation.nil? || %w[-h --help].include?(operation) ? 0 : 1)
  end
  F2Validation.run(operation)
end
