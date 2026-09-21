# frozen_string_literal: true
# Run only via the root agent's explicit isolated-target launcher. No subprocesses,
# schema loading, database creation, cleanup, production helpers or expected-query
# derivation occur in this harness.
require_relative "f3_guard"
require_relative "f3_synthetic_fixture"
require_relative "f3_sql_probe_support"
require "fileutils"
require "rack/mock"

module F3IndependentAPI
  DOMAIN_TABLES = %w[catalogue_documents catalogue_identifiers composers external_references held_items import_logs instrumentations movements performances source_descriptions source_references source_relations work_classification_terms work_titles works].freeze
  HEADERS = %w[x-total-count x-page x-per-page x-total-pages link].freeze
  module_function

  def write(path, value)
    raise "Evidence already exists: #{File.basename(path)}" if File.exist?(path)
    File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) { |file| file.write(value.is_a?(String) ? value : JSON.pretty_generate(value) + "\n") }
  end

  def sql(connection, statement, *values)
    binds = values.map { |value| ActiveRecord::Relation::QueryAttribute.new(nil, value, ActiveRecord::Type::String.new) }
    connection.exec_query(statement, "F3 independent SQL", binds).to_a
  end

  def snapshot(connection)
    tables = DOMAIN_TABLES.to_h do |table|
      [table, sql(connection, "SELECT row_to_json(r)::text AS row FROM (SELECT * FROM #{connection.quote_table_name(table)} ORDER BY id) r").map { |row| JSON.parse(row.fetch("row")) }]
    end
    sequence_names = sql(connection, "SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' ORDER BY sequencename").map { |row| row.fetch("sequencename") }
    sequences = sequence_names.to_h do |name|
      [name, sql(connection, "SELECT last_value, is_called FROM #{connection.quote_table_name(name)}").first]
    end
    schema = {
      columns: sql(connection, "SELECT table_name,column_name,ordinal_position,column_default,is_nullable,data_type,character_maximum_length,numeric_precision,numeric_scale,datetime_precision,udt_schema,udt_name,is_identity,identity_generation FROM information_schema.columns WHERE table_schema='public' ORDER BY table_name,ordinal_position"),
      constraints: sql(connection, "SELECT c.relname AS table_name,con.conname,con.contype,con.condeferrable,con.condeferred,con.convalidated,pg_get_constraintdef(con.oid,true) AS definition FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' ORDER BY c.relname,con.conname"),
      indexes: sql(connection, "SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname='public' ORDER BY tablename,indexname"),
      sequences: sql(connection, "SELECT sequencename,data_type,start_value,min_value,max_value,increment_by,cycle,cache_size FROM pg_sequences WHERE schemaname='public' ORDER BY sequencename"),
      relations: sql(connection, "SELECT c.relname,c.relkind,c.relpersistence,c.reloptions FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' ORDER BY c.relname"),
      triggers: sql(connection, "SELECT event_object_table,trigger_name,event_manipulation,action_timing,action_statement FROM information_schema.triggers WHERE trigger_schema='public' ORDER BY event_object_table,trigger_name,event_manipulation"),
      extensions: sql(connection, "SELECT extname,extversion FROM pg_extension ORDER BY extname"),
      schema_migrations: sql(connection, "SELECT * FROM schema_migrations ORDER BY version"),
      ar_internal_metadata: sql(connection, "SELECT * FROM ar_internal_metadata ORDER BY key")
    }
    F3APIProbe::SQLFacts.new { connection }.state.merge("structural_schema" => schema)
  end

  def verify_fixture(connection, truth)
    stored = sql(connection, "SELECT w.id,w.title,w.catalogue_number,w.composition_date,w.composition_year,w.genre,w.source_file,w.source_identifier,w.composer_id,c.name AS composer,w.catalogue_document_id FROM works w JOIN composers c ON c.id=w.composer_id ORDER BY w.title,w.id")
    raise "Synthetic target membership must be exactly 48" unless stored.size == truth.fetch("rows").size
    by_file = stored.to_h { |row| [row.fetch("source_file"), row] }
    id_map = {}; summary_map = {}
    truth.fetch("rows").each do |row|
      value = by_file.fetch(row.fetch("source_file"))
      %w[title catalogue_number composition_date composition_year genre source_file source_identifier composer].each do |field|
        raise "Independent SQL fixture mismatch #{row.fetch('external_key')} #{field}" unless value[field] == row[field]
      end
      raise "Projection association mismatch" unless value["catalogue_document_id"].present? == row.fetch("projected_demo")
      id = value.fetch("id");id_map[row.fetch("external_key")] = id
      retained_titles = sql(connection, "SELECT text FROM work_titles WHERE work_id=$1::bigint ORDER BY source_order,id", id.to_s).map { |item| item.fetch("text") }
      retained_terms = sql(connection, "SELECT text FROM work_classification_terms WHERE work_id=$1::bigint ORDER BY source_order,id", id.to_s).map { |item| item.fetch("text") }
      instruments = sql(connection, "SELECT name FROM instrumentations WHERE work_id=$1::bigint ORDER BY name,id", id.to_s).map { |item| item.fetch("name") }
      identifiers = sql(connection, "SELECT identifier_type AS type,value FROM catalogue_identifiers WHERE work_id=$1::bigint ORDER BY id", id.to_s)
      raise "Independent SQL title mismatch" unless retained_titles == row.fetch("retained_titles")
      raise "Independent SQL classification mismatch" unless retained_terms == row.fetch("retained_classifications")
      raise "Independent SQL instrumentation mismatch" unless instruments == row.fetch("instrumentation").sort
      raise "Independent SQL identifier mismatch" unless identifiers == row.fetch("catalogue_identifiers")
      summary_map[id] = value.slice("id", "title", "catalogue_number", "composition_date", "composition_year", "genre", "source_file").merge("composer" => {"id" => value.fetch("composer_id"), "name" => value.fetch("composer")}, "instrumentation" => instruments)
    end
    expected = truth.fetch("ordering").fetch("frozen_ordered_external_keys").map { |key| id_map.fetch(key) }
    raise "Independent SQL ordering disagrees with frozen truth" unless stored.map { |row| row.fetch("id") } == expected
    truth.fetch("rows").group_by { |row| row.fetch("title") }.each_value do |group|
      ids = group.sort_by { |row| row.fetch("insertion_rank") }.map { |row| id_map.fetch(row.fetch("external_key")) }
      raise "Synthetic insertion did not preserve frozen ID tie order" unless ids == ids.sort && ids.uniq.size == ids.size
    end
    facts = F3APIProbe::SQLFacts.new { connection }
    detail_map = %w[F3-W001 F3-W002 F3-W016].to_h { |key| [id_map.fetch(key), facts.detail(id_map.fetch(key))] }
    { id_map: id_map, summary_map: summary_map, detail_map: detail_map, rows: stored, collation: sql(connection, "SELECT current_database() AS database,datcollate,datctype FROM pg_database WHERE datname=current_database()").first }
  end

  def request(case_row, id_map)
    spec = case_row.fetch("request")
    path = spec.fetch("path").gsub(/\{id:([^}]+)\}/) { id_map.fetch(Regexp.last_match(1)).to_s }
    environment = Rack::MockRequest.env_for(path, method: "GET")
    environment["QUERY_STRING"] = spec.fetch("query", "")
    environment["HTTP_HOST"] = "www.example.com"
    environment["HTTP_ACCEPT"] = spec["accept"] if spec.key?("accept")
    started = Time.now.utc.iso8601(6)
    status, headers, body = Rails.application.call(environment)
    content = +"";body.each { |piece| content << piece }
    body.close if body.respond_to?(:close)
    { "status" => status, "headers" => headers.to_h.transform_keys(&:downcase), "body" => content,
      "started_utc" => started, "ended_utc" => Time.now.utc.iso8601(6), "path" => path, "query" => spec.fetch("query", ""), "accept" => spec["accept"] }
  end

  def compare(case_row, observed, id_map, summary_map, truth_by_key, detail_map)
    expected = case_row.fetch("expected");failures = []
    fail_if = ->(condition, message) { failures << message if condition }
    fail_if.call(observed.fetch("status") != expected.fetch("status"), "status expected #{expected.fetch('status')} observed #{observed.fetch('status')}")
    headers = observed.fetch("headers")
    fail_if.call(!headers.fetch("content-type", "").start_with?(expected.fetch("content_type_prefix")), "non-JSON content type")
    begin
      parsed = JSON.parse(observed.fetch("body"))
    rescue JSON::ParserError
      return failures + ["response body is not JSON"]
    end
    if expected.key?("json")
      fail_if.call(parsed != expected.fetch("json"), "error payload differs from frozen exact safe error")
    elsif expected["json_type"] == "array"
      fail_if.call(!parsed.is_a?(Array), "index is not a bare array")
      if parsed.is_a?(Array)
        wanted = expected.fetch("page_external_keys").map { |key| id_map.fetch(key) }
        fail_if.call(parsed.map { |row| row["id"] } != wanted, "page membership/order differs")
        parsed.each do |row|
          fail_if.call(row != summary_map[row["id"]], "summary fields differ from independent SQL fixture for id #{row['id']}")
        end
      end
      expected.fetch("headers").each { |name, value| fail_if.call(headers[name.downcase] != value, "#{name} differs") }
      wanted_links = expected.fetch("links").map { |rel, url| "<#{url}>; rel=\"#{rel}\"" }.join(", ")
      wanted_links = nil if wanted_links.empty?
      fail_if.call(headers["link"] != wanted_links, "relative Link header differs")
    elsif expected["json_type"] == "object"
      fail_if.call(!parsed.is_a?(Hash), "detail is not an object")
      if parsed.is_a?(Hash)
        key = expected.fetch("external_key");id = id_map.fetch(key);truth = truth_by_key.fetch(key)
        fail_if.call(parsed["id"] != id, "detail identity differs")
        detail_diffs = F3APIProbe.compare_work(detail_map.fetch(id), parsed)
        fail_if.call(detail_diffs.any?, "exact retained SQL-to-detail semantics differ")
        fail_if.call((expected.fetch("required_fields") - parsed.keys).any?, "existing detail fields removed")
        summary_map.fetch(id).each { |name, value| fail_if.call(parsed[name] != value, "detail summary differs at #{name}") }
        fail_if.call(parsed.fetch("titles", []).map { |row| row["text"] } != truth.fetch("retained_titles"), "detail retained titles differ")
        fail_if.call(parsed.fetch("classification_terms", []).map { |row| row["text"] } != truth.fetch("retained_classifications"), "detail classification differs")
        fail_if.call(parsed.dig("availability", "status") != (truth.fetch("projected_demo") ? "demo" : "legacy_unvalidated"), "detail availability marker differs")
        fail_if.call(parsed.dig("catalogue_sources", "projection", "summary", "state") != "not_projected", "synthetic source availability was invented")
      end
    end
    if expected["pagination_headers_absent"]
      HEADERS.each { |name| fail_if.call(headers.key?(name), "unexpected #{name} on non-index-success") }
    end
    failures
  end
end

started_utc = Time.now.utc.iso8601(6)
acceptance = File.expand_path(ENV.fetch("F3_ACCEPTANCE_DIR"))
out = File.expand_path(ENV.fetch("F3_API_OUTPUT_DIR"))
raise "Evidence and acceptance must be in new F3 scratch" unless [acceptance, out].all? { |path| path.start_with?("/private/tmp/www_f3_") }
raise "Experiment output must be new" if File.exist?(out)
Dir.mkdir(out, 0o700)
contract = JSON.parse(File.read(File.join(acceptance, "f3_api_cases_v1.json")))
truth = JSON.parse(File.read(File.join(acceptance, "f3_synthetic_truth_v1.json")))
manifest = JSON.parse(File.read(File.join(acceptance, "f3_prospective_freeze_manifest.json")))
manifest.fetch("files").each do |row|
  raise "Prospective artifact changed after freeze: #{row.fetch('path')}" unless Digest::SHA256.file(File.join(acceptance, row.fetch("path"))).hexdigest == row.fetch("sha256")
end
raise "Prospective fixture must contain 48 works" unless truth.fetch("rows").size == 48

guard = F3Guard.boot!
results = []; responses = {}; fixture_check = nil; before = nil; after = nil; controls = nil; traversals = []; comparison_controls = []; failure = nil
begin
  guard.with_phase("synthetic_preflight") do
    controls = guard.run_negative_controls!
    guard.schema_current!
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      raise "Synthetic experiment target is not empty" unless F3IndependentAPI::DOMAIN_TABLES.all? { |table| connection.select_value("SELECT COUNT(*) FROM #{connection.quote_table_name(table)}").zero? }
    end
  end
  guard.with_phase("synthetic_fixture_insert") { F3SyntheticFixture.load!(truth) }
  guard.with_phase("independent_fixture_sql") do
    ActiveRecord::Base.connection_pool.with_connection { |connection| fixture_check = F3IndependentAPI.verify_fixture(connection, truth) }
  end
  F3IndependentAPI.write(File.join(out, "independent_sql_fixture.json"), fixture_check)
  truth_by_key = truth.fetch("rows").to_h { |row| [row.fetch("external_key"), row] }
  guard.with_phase("before_get_snapshot") do
    ActiveRecord::Base.connection_pool.with_connection { |connection| before = F3IndependentAPI.snapshot(connection) }
  end
  F3IndependentAPI.write(File.join(out, "before_gets.json"), before)
  contract.fetch("cases").each do |case_row|
    id = case_row.fetch("case_id");phase = "request_#{id}";observed = nil
    configuration = guard.configuration!(ActiveRecord::Base.connection_pool.db_config)
    guard.with_phase(phase) { observed = F3IndependentAPI.request(case_row, fixture_check.fetch(:id_map)) }
    events = guard.events_for(phase).select { |event| event[:kind] == "sql" }
    observed["sql_observation"] = { "guarded_query_events" => events.size, "no_sql" => events.empty?, "validated_configuration" => configuration, "identity_guards" => events.map { |event| event[:sequence] } }
    F3IndependentAPI.write(File.join(out, "#{id}.json"), observed)
    failures = F3IndependentAPI.compare(case_row, observed, fixture_check.fetch(:id_map), fixture_check.fetch(:summary_map), truth_by_key, fixture_check.fetch(:detail_map))
    results << { case_id: id, status: failures.empty? ? "PASS" : "FAIL", failures: failures, observed_ref: "#{id}.json", expected_ref: "f3_api_cases_v1.json##{id}", sql_queries: events.size }
    responses[id] = observed
  end
  # Repeat an unchanged request with the same independent comparator and body.
  repeated_case = contract.fetch("cases").find { |row| row.fetch("case_id") == "index-default" }
  repeat = nil
  guard.with_phase("request_repeat_default") { repeat = F3IndependentAPI.request(repeated_case, fixture_check.fetch(:id_map)) }
  F3IndependentAPI.write(File.join(out, "repeated_default.json"), repeat)
  repeat_errors = F3IndependentAPI.compare(repeated_case, repeat, fixture_check.fetch(:id_map), fixture_check.fetch(:summary_map), truth_by_key, fixture_check.fetch(:detail_map))
  repeat_errors << "repeat body changed" unless repeat.fetch("body") == responses.fetch("index-default").fetch("body")
  results << { case_id: "stable-repeated-default", status: repeat_errors.empty? ? "PASS" : "FAIL", failures: repeat_errors }

  contract.fetch("comparison_controls").each do |control|
    altered = Marshal.load(Marshal.dump(repeated_case))
    case control.fetch("name")
    when "wrong-member"
      altered["expected"]["page_external_keys"][0] = "F3-W001"
    when "wrong-order"
      altered["expected"]["page_external_keys"][0, 2] = altered["expected"]["page_external_keys"][0, 2].reverse
    when "wrong-total"
      altered["expected"]["headers"]["X-Total-Count"] = "49"
    end
    detected = F3IndependentAPI.compare(altered, responses.fetch("index-default"), fixture_check.fetch(:id_map), fixture_check.fetch(:summary_map), truth_by_key, fixture_check.fetch(:detail_map))
    comparison_controls << { name: control.fetch("name"), status: detected.any? ? "PASS" : "FAIL", deliberately_wrong_expectation_detected: detected.any?, unchanged_response_sha256: Digest::SHA256.hexdigest(responses.fetch("index-default").fetch("body")), comparator_errors: detected }
  end
  groups = { "default-20" => (1..3).map { |page| "default-traversal-page-#{page}" }, "size-7" => (1..7).map { |page| "seven-traversal-page-#{page}" }, "size-100" => ["max-page-size-1"] }
  contract.fetch("cases").select { |row| row.fetch("case_id").start_with?("filter-") && row.fetch("case_id").end_with?("-p1") }.each do |row|
    stem = row.fetch("case_id").delete_suffix("-p1");count = row.fetch("expected").fetch("headers").fetch("X-Total-Pages").to_i
    groups[stem] = count.zero? ? [row.fetch("case_id")] : (1..count).map { |page| "#{stem}-p#{page}" }
  end
  groups.each do |name, ids|
    first_case = contract.fetch("cases").find { |row| row.fetch("case_id") == ids.first }
    expected_keys = first_case.fetch("expected").fetch("filtered_ordered_external_keys")
    observed_ids = ids.flat_map { |id| JSON.parse(responses.fetch(id).fetch("body")).map { |row| row["id"] } }
    expected_ids = expected_keys.map { |key| fixture_check.fetch(:id_map).fetch(key) }
    traversals << { name: name, pages: ids, expected_external_keys: expected_keys, expected_ids: expected_ids, observed_ids: observed_ids, unique: observed_ids.uniq.size == observed_ids.size, status: observed_ids == expected_ids && observed_ids.uniq.size == observed_ids.size ? "PASS" : "FAIL" }
  end
rescue StandardError => error
  failure = { class: error.class.name, message: error.message, backtrace: error.backtrace }
ensure
  if before
    guard.with_phase("after_get_snapshot") do
      ActiveRecord::Base.connection_pool.with_connection { |connection| after = F3IndependentAPI.snapshot(connection) }
    end
    F3IndependentAPI.write(File.join(out, "after_gets.json"), after)
  end
  report = { status: failure.nil? && results.size == contract.fetch("cases").size + 1 && results.all? { |row| row[:status] == "PASS" } && comparison_controls.size == 3 && comparison_controls.all? { |row| row[:status] == "PASS" } && traversals.all? { |row| row[:status] == "PASS" } && before == after && guard.summary[:refusals].empty? ? "PASS" : "FAIL", started_utc: started_utc, ended_utc: Time.now.utc.iso8601(6), prospective_manifest_sha256: Digest::SHA256.file(File.join(acceptance, "f3_prospective_freeze_manifest.json")).hexdigest, case_count: results.size, results: results, complete_traversals: traversals, comparator_negative_controls: comparison_controls, preserved_domain_tables_sequences_schema: !before.nil? && before == after, wrong_identity_controls: controls, guard: guard.summary, unexpected_failure: failure, fixture_retention: "All 48 synthetic works retained in this newly owned target. No new cleanup/deletion." }
  F3IndependentAPI.write(File.join(out, "result.json"), report)
  puts JSON.pretty_generate(report.slice(:status, :case_count, :preserved_domain_tables_sequences_schema, :unexpected_failure))
end
exit(report.fetch(:status) == "PASS" ? 0 : 1)
