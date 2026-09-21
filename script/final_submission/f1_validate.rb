# frozen_string_literal: true

# Deliberately has no implicit database, service, package or cleanup operation.
require_relative "f1_guard"

module F1Validation
  F1_MIGRATION = 20260919180000

  def self.migrate!(guard)
    baseline = Pathname.new(ENV.fetch("F1_BASELINE_SCHEMA")).realpath
    expected_hash = ENV.fetch("F1_BASELINE_SCHEMA_SHA256")
    guard.refuse!("Baseline schema must be external reviewed F1 scratch") unless baseline.to_s.start_with?("/private/tmp/www_f1_")
    guard.refuse!("Baseline schema hash mismatch") unless Digest::SHA256.file(baseline).hexdigest == expected_hash
    require "active_record/tasks/database_tasks"
    pool = ActiveRecord::Base.connection_pool
    config = pool.db_config
    guard.verify_all!
    guard.refuse!("New target does not have the verified baseline schema") unless ActiveRecord::Tasks::DatabaseTasks.schema_up_to_date?(config, nil, baseline.to_s)
    context = pool.migration_context
    applied = context.get_all_versions
    pending = context.migrations.reject { |migration| applied.include?(migration.version) }.map(&:version)
    guard.refuse!("Only the additive F1 migration is allowed") unless pending == [F1_MIGRATION]
    guard.with_phase("f1_additive_migration") { context.migrate(F1_MIGRATION) }
    guard.with_phase("observed_schema_dump") do
      require "active_record/schema_dumper"
      schema = Rails.root.join("db/schema.rb")
      File.open(schema, "w:utf-8") { |file| ActiveRecord::SchemaDumper.dump(pool, file) }
      # Match Rails' schema-load metadata so the unmodified test helper never
      # decides to purge the new target after a legitimate migration/dump.
      pool.internal_metadata.create_table_and_set_flags("test", Digest::SHA1.file(schema).hexdigest)
    end
    guard.schema_current!
    guard.ensure_no_refusals!
    { status: "PASS", operation: "f1_additive_migration", applied_version: F1_MIGRATION,
      schema_sha256: Digest::SHA256.file(Rails.root.join("db/schema.rb")).hexdigest, guard: guard.summary }
  end

  def self.run(operation)
    if operation == "suite"
      load File.expand_path("f1_suite.rb", __dir__)
    elsif operation == "source-api"
      load File.expand_path("f1_source_api_check.rb", __dir__)
    else
      guard = F1Guard.boot!
      case operation
      when "verify"
        guard.schema_current!
        guard.with_phase("eager_load") { Rails.application.eager_load! }
        guard.ensure_no_refusals!
        puts JSON.pretty_generate(status: "PASS", operation: "verify", guard: guard.summary)
      when "migrate"
        puts JSON.pretty_generate(migrate!(guard))
      else
        raise ArgumentError, "Unknown validation operation"
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  operation = ARGV.shift
  unless %w[verify migrate suite source-api].include?(operation)
    puts <<~HELP
      F1 isolated validation: ruby script/final_submission/f1_validate.rb OPERATION
      Operations: verify, migrate, suite, source-api.
      Run from a fresh external selective copy; never the original repository.
      Required: RAILS_ENV=test RACK_ENV=test PARALLEL_WORKERS=1,
      an explicit DATABASE_URL and F1_APP_ROOT, F1_TARGET_JSON, F1_GUARD_LOG.
      The target descriptor must identify a separately created, initially empty
      database on the reviewed private F1 PostgreSQL14.23 instance, with retained
      creation evidence. A descriptor alone is not permission to adopt a database.
      Remove inherited PostgreSQL/service and other *_DATABASE_URL overrides.
      migrate also requires F1_BASELINE_SCHEMA and F1_BASELINE_SCHEMA_SHA256.
      suite requires F1_SUITE_RESULT_JSON; the fixed seed is 190926, one worker.
      source-api requires F1_EXPECTATIONS_JSON, F1_EXPECTATIONS_SHA256,
      F1_SOURCE_DIR and F1_VALIDATION_OUTPUT (all explicit external review inputs).
      No operation installs packages, starts a service, creates/drops a database,
      seeds/replants, clears logs/tmp or invokes setup/CI. Preserve all outputs.
    HELP
    exit(operation.nil? || %w[-h --help].include?(operation) ? 0 : 1)
  end
  F1Validation.run(operation)
end
