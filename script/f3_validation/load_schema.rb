# frozen_string_literal: true
require_relative "f3_guard"

guard = F3Guard.boot!
guard.with_phase("load_schema") do
  target = guard.target
  guard.refuse!("Schema load requires a recorded newly created target") unless target["newly_created"] == true
  evidence = target["creation_evidence"]
  guard.refuse!("Missing database-creation evidence") unless evidence.is_a?(String) && File.file?(evidence)
  schema = Rails.root.join("db/schema.rb")
  expected_sha = ENV.fetch("F3_SCHEMA_SHA256")
  guard.refuse!("Schema input hash mismatch") unless Digest::SHA256.file(schema).hexdigest == expected_sha
  ActiveRecord::Base.connection_pool.with_connection do |connection|
    guard.assert_connection!(connection)
    objects = connection.select_all(<<~SQL).to_a
      SELECT n.nspname AS schema_name, c.relname AS name, c.relkind AS kind
      FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
        AND n.nspname NOT LIKE 'pg_toast%' AND n.nspname NOT LIKE 'pg_temp%'
        AND c.relkind IN ('r','p','v','m','S','f')
    SQL
    guard.refuse!("Target has existing application objects; schema load refused") unless objects.empty?
  end
  controls = guard.run_negative_controls!
  require "active_record/tasks/database_tasks"
  # The single explicit current environment cannot expand into development.
  # Every temporary adapter created by this Rails helper remains guarded.
  ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, schema.to_s, "test")
  guard.schema_current!
  guard.ensure_no_refusals!
  puts JSON.generate(status: "PASS", operation: "baseline_schema_load",
                     schema_sha256: expected_sha, controls: controls, guard: guard.summary)
end
