# Invoked by bin/setup through Rails runner, after explicit-target validation.
# Connecting to the existing pool fails if its database is absent. Unlike
# db:prepare/db:migrate, this path never creates a database or executes/writes a schema file.
require_relative "commands"
require_relative "schema"
Release::Commands.new.child_environment(:setup)
pool = ActiveRecord::Base.connection_pool
pool.with_connection { |connection| connection.select_value("SELECT current_database()") }
pool.migration_context.migrate
Release::Schema.record_current(pool, File.binread(Rails.root.join("db/schema.rb")))
puts "Schema migrations and schema-file comparison complete for the explicitly selected existing database."
