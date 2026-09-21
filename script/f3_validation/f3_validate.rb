# frozen_string_literal: true
# Explicit dispatcher only: resource provisioning and fresh target selection
# belong to the reviewed external launcher. No default app, database or cleanup.
operations = {
  "schema" => "load_schema.rb",
  "suite" => "run_suite.rb",
  "source" => "f3_source_api_check.rb",
  "synthetic" => "f3_synthetic_api_experiment.rb"
}.freeze
operation = ARGV.shift
abort "Usage: ruby f3_validate.rb schema|suite|source|synthetic (explicit F3 environment required)" unless operations.key?(operation) && ARGV.empty?
%w[F3_APP_ROOT F3_TARGET_JSON F3_GUARD_LOG DATABASE_URL RAILS_ENV RACK_ENV PARALLEL_WORKERS].each { |name| ENV.fetch(name) }
raise "Only explicit test environment and one worker permitted" unless ENV.values_at("RAILS_ENV", "RACK_ENV", "PARALLEL_WORKERS") == ["test", "test", "1"]
load File.join(__dir__, operations.fetch(operation))
