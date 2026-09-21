# frozen_string_literal: true

# Standalone expectation/comparison support. Never calls application scopes,
# association readers, importer extraction helpers, or controller serializers.
require "json"
require "digest"
require "date"
require "time"

module F2APIProbe
  DOMAIN_TABLES = %w[composers works catalogue_identifiers movements instrumentations source_references performances external_references import_logs catalogue_documents work_titles work_classification_terms source_descriptions held_items source_relations].freeze
  UNORDERED_CHILDREN = %w[catalogue_identifiers sources external_references].freeze
  ORDER_KEYS = { "movements" => "position", "performances" => "performed_on" }.freeze

  def self.json_value(value)
    case value
    when Hash then value.transform_keys(&:to_s).transform_values { |v| json_value(v) }
    when Array then value.map { |v| json_value(v) }
    when Time, DateTime then value.iso8601(6)
    when Date then value.iso8601
    else value
    end
  end

  def self.canonical(value)
    case value
    when Hash then value.keys.sort.to_h { |key| [key, canonical(value[key])] }
    when Array then value.map { |v| canonical(v) }
    else value
    end
  end

  def self.multiset(array)
    array.each_with_object(Hash.new(0)) { |value, memo| memo[JSON.generate(canonical(value))] += 1 }.sort.to_h
  end

  # F2 nested arrays are ordered source facts; compare every parent and value.
  def self.deep_compare(expected, actual, path = "$", diffs = [])
    if expected.is_a?(Hash) && actual.is_a?(Hash)
      if expected.keys.sort != actual.keys.sort
        diffs << { path: path, reason: "object keys differ", expected: expected.keys.sort, actual: actual.keys.sort }
      end
      expected.each { |key, value| deep_compare(value, actual[key], "#{path}.#{key}", diffs) }
    elsif expected.is_a?(Array) && actual.is_a?(Array)
      if expected.length != actual.length
        diffs << { path: path, reason: "ordered array length differs", expected: expected.length, actual: actual.length }
      end
      expected.each_with_index { |value, index| deep_compare(value, actual[index], "#{path}[#{index}]", diffs) }
    elsif expected != actual
      diffs << { path: path, reason: "value or type differs", expected: expected, actual: actual }
    end
    diffs
  end

  # Same comparator is used for actual observations and deliberate control.
  # Scalars/keys are exact; array multisets preserve duplicate multiplicity.
  # Declared order keys are checked separately without inventing tie order.
  def self.compare_work(expected, actual, path = "$", diffs = [])
    unless expected.is_a?(Hash) && actual.is_a?(Hash)
      diffs << { path: path, reason: "expected/actual work is not object", expected: expected, actual: actual }
      return diffs
    end
    if expected.keys.sort != actual.keys.sort
      diffs << { path: path, reason: "object keys differ", expected: expected.keys.sort, actual: actual.keys.sort }
    end
    expected.each do |key, value|
      observed = actual[key]
      if key == "catalogue_sources"
        deep_compare(value, observed, "#{path}.#{key}", diffs)
      elsif value.is_a?(Array)
        unless observed.is_a?(Array)
          diffs << { path: "#{path}.#{key}", reason: "expected array", actual: observed }
          next
        end
        if multiset(value) != multiset(observed)
          diffs << { path: "#{path}.#{key}", reason: "duplicate-aware multiset differs", expected: multiset(value), actual: multiset(observed) }
        end
        if key == "instrumentation" && value != observed
          diffs << { path: "#{path}.#{key}", reason: "declared name order differs", expected: value, actual: observed }
        elsif %w[titles classification_terms].include?(key) && value != observed
          diffs << { path: "#{path}.#{key}", reason: "declared source row order differs", expected: value, actual: observed }
        elsif ORDER_KEYS.key?(key)
          field = ORDER_KEYS.fetch(key)
          expected_order = value.map { |v| v.fetch(field) }
          observed_order = observed.map { |v| v.is_a?(Hash) ? v[field] : "<non-object>" }
          if expected_order != observed_order
            diffs << { path: "#{path}.#{key}", reason: "declared #{field} order differs; equal-key ties unspecified", expected: expected_order, actual: observed_order }
          end
        end
      elsif value != observed
        diffs << { path: "#{path}.#{key}", reason: "field differs", expected: value, actual: observed }
      end
    end
    diffs
  end

  def self.compare_index(expected, actual)
    diffs = []
    return { "pass" => false, "diffs" => [{ reason: "index is not an array", actual_class: actual.class.name }] } unless actual.is_a?(Array)
    expected_ids = expected.map { |w| w.fetch("id") }
    actual_ids = actual.map { |w| w.is_a?(Hash) ? w["id"] : "<non-object>" }
    if multiset(expected_ids) != multiset(actual_ids)
      diffs << { path: "$", reason: "identity multiset differs", expected: multiset(expected_ids), actual: multiset(actual_ids) }
    end
    expected.each do |work|
      candidates = actual.select { |w| w.is_a?(Hash) && w["id"] == work["id"] }
      compare_work(work, candidates.first, "$[id=#{work['id']}]", diffs) if candidates.length == 1
    end
    # Direct SQL orders by title using server collation. Identical-title rows
    # can permute within their tie group without being reported as a failure.
    expected_title_order = expected.map { |w| w.fetch("title") }
    observed_title_order = actual.map { |w| w.is_a?(Hash) ? w["title"] : nil }
    if expected_title_order != observed_title_order
      diffs << { path: "$", reason: "database title ordering differs; equal-title ties unspecified", expected: expected_title_order, actual: observed_title_order }
    end
    { "pass" => diffs.empty?, "diffs" => diffs, "expected_ordered_ids" => expected_ids, "observed_ordered_ids" => actual_ids,
      "expected_identity_multiset" => multiset(expected_ids), "observed_identity_multiset" => multiset(actual_ids),
      "expected_title_order" => expected_title_order, "observed_title_order" => observed_title_order }
  end

  class SQLFacts
    SOURCE_FIELDS = %w[xml_id locator source_order label state source_attributes parent_metadata availability identifiers titles classification_terms publication physical_description notes links].freeze
    ITEM_FIELDS = %w[xml_id locator source_order label state source_attributes parent_metadata availability identifiers physical_locations physical_description links].freeze
    RELATION_FIELDS = %w[xml_id locator relation_order token_order rel raw_target target_token source_attributes parent_metadata resolution_state resolution_reason expression_context].freeze

    attr_reader :statements

    def initialize(&connection_provider)
      raise ArgumentError, "Explicit current-connection provider required" unless connection_provider
      @connection_provider = connection_provider
      @statements = []
    end

    def connection = @connection_provider.call

    def rows(sql)
      @statements << sql
      result = connection.select_all(sql)
      # PostgreSQL JSONB may arrive as a string in Result#to_a. Decode via the
      # adapter's SQL column types, independently of all application models.
      values = result.cast_values
      decoded = values.map do |row|
        result.columns.zip(result.columns.one? ? [row] : row).to_h
      end
      F2APIProbe.json_value(decoded)
    end

    def quote(value) = connection.quote(value)

    def summary(work)
      composer = rows("SELECT id, name FROM composers WHERE id = #{Integer(work.fetch('composer_id'))}")
      raise "Composer must resolve uniquely" unless composer.length == 1
      instruments = rows("SELECT name FROM instrumentations WHERE work_id = #{Integer(work.fetch('id'))} ORDER BY name ASC")
      { "id" => work.fetch("id"), "title" => work.fetch("title"), "composer" => composer.first,
        "catalogue_number" => work["catalogue_number"], "composition_date" => work["composition_date"],
        "composition_year" => work["composition_year"], "genre" => work["genre"],
        "instrumentation" => instruments.map { |r| r.fetch("name") }, "source_file" => work.fetch("source_file") }
    end

    def index
      rows("SELECT * FROM works ORDER BY title ASC").map { |work| summary(work) }
    end

    def legacy_detail(work_id)
      work = rows("SELECT * FROM works WHERE id = #{Integer(work_id)}")
      raise "Detail SQL work must resolve uniquely" unless work.length == 1
      result = summary(work.first)
      result["source_identifier"] = work.first["source_identifier"]
      result["catalogue_identifiers"] = rows("SELECT identifier_type AS type, value FROM catalogue_identifiers WHERE work_id = #{Integer(work_id)} ORDER BY id ASC")
      result["movements"] = rows("SELECT position, title, tempo_marking, duration FROM movements WHERE work_id = #{Integer(work_id)} ORDER BY position ASC, id ASC")
      result["sources"] = rows("SELECT label, source_type AS type, repository, description FROM source_references WHERE work_id = #{Integer(work_id)} ORDER BY id ASC")
      result["performances"] = rows("SELECT performed_on, location, performers, note FROM performances WHERE work_id = #{Integer(work_id)} ORDER BY performed_on ASC, id ASC")
      result["external_references"] = rows("SELECT label, url FROM external_references WHERE work_id = #{Integer(work_id)} ORDER BY id ASC")
      result
    end

    def detail(work_id)
      work = rows("SELECT * FROM works WHERE id = #{Integer(work_id)}").fetch(0)
      legacy_detail(work_id).merge(f1_projection(work)).merge("catalogue_sources" => catalogue_sources(work))
    end

    def timestamp(value) = value && Time.iso8601(value).iso8601(3)

    def f1_projection(work)
      id = Integer(work.fetch("id"))
      document_id = work["catalogue_document_id"]
      doc = document_id && rows("SELECT * FROM catalogue_documents WHERE id = #{Integer(document_id)}").fetch(0)
      titles = rows("SELECT text, raw_text, source_type, language, xml_id, source_order, locator, source_attributes AS attributes FROM work_titles WHERE work_id = #{id} ORDER BY source_order, id")
      titles.each { |row| row["selected_for_display"] = row["source_order"] == work["display_title_order"] }
      terms = rows("SELECT text, raw_text, xml_id, source_order, locator, source_attributes AS attributes, classification_metadata, term_list_metadata FROM work_classification_terms WHERE work_id = #{id} ORDER BY source_order, id")
      identity = document_id ? "catalogue_document_id = #{Integer(document_id)}" : "work_id = #{id}"
      attempts = rows("SELECT * FROM import_logs WHERE #{identity} ORDER BY imported_at DESC, id DESC")
      latest = attempts.first
      successful = attempts.find { |row| row["status"] == "success" }
      warning_rows = latest ? Array(latest["warnings"]) : []
      warning_rows.each do |warning|
        raise "Warning outside the declared source-run diagnostic oracle" unless warning.is_a?(String) && !warning.empty? && warning == warning.lines.first.to_s.strip && warning.length <= 512 && !warning.match?(%r{<|://|/(?:Users|private|tmp)/})
      end
      raise "Source-run error summary requires a separate synthetic oracle" if latest && latest["error_message"]
      visible_warnings = warning_rows.first(20)
      visible_warnings << "Additional warnings are retained in the local import log." if warning_rows.length > 20
      selected = titles.find { |row| row["source_order"] == work["display_title_order"] }
      {
        "titles" => titles, "classification_terms" => terms,
        "display_title_policy" => doc && {
          "name" => "main_untyped_uniform_alternative_subordinate_v1", "selection_reason" => work["display_title_reason"],
          "source_order" => work["display_title_order"], "xml_id" => selected && selected["xml_id"],
          "subordinate_fallback" => !!(selected && selected["source_type"] == "subordinate")
        },
        "latest_import_attempt" => latest && {
          "id" => latest["id"], "status" => latest["status"], "imported_at" => timestamp(latest["imported_at"]),
          "error_message" => nil, "warnings" => visible_warnings,
          "attempted_profile" => latest["attempted_profile"], "attempted_catalogue" => latest["attempted_catalogue"],
          "attempted_record_key" => latest["attempted_record_key"], "attempted_sha256" => latest["attempted_sha256"],
          "previous_committed_sha256" => latest["previous_committed_sha256"]
        },
        "last_successful_import" => successful && {
          "id" => successful["id"], "imported_at" => timestamp(successful["imported_at"]), "input_profile" => successful["attempted_profile"],
          "catalogue" => successful["attempted_catalogue"], "record_key" => successful["attempted_record_key"], "committed_sha256" => successful["attempted_sha256"]
        },
        "availability" => doc ? {
          "status" => doc["input_profile"] == "demo" ? "demo" : "official", "input_profile" => doc["input_profile"],
          "titles" => titles.empty? ? "missing" : "present", "classification_terms" => terms.empty? ? "missing" : "present"
        } : { "status" => "legacy_unvalidated", "input_profile" => nil, "titles" => "unvalidated", "classification_terms" => "unvalidated" }
      }
    end

    def public_fields(row, names)
      names.to_h { |name| [name == "source_attributes" ? "attributes" : name, row.fetch(name)] }
    end

    def catalogue_sources(work)
      unless work["catalogue_document_id"]
        return { "document" => nil, "projection" => { "version" => nil, "summary" => { "state" => "not_projected" } }, "descriptions" => [] }
      end
      document_id = Integer(work.fetch("catalogue_document_id"))
      doc = rows("SELECT * FROM catalogue_documents WHERE id = #{document_id}").fetch(0)
      sources = rows("SELECT * FROM source_descriptions WHERE catalogue_document_id = #{document_id} ORDER BY source_order, id")
      descriptions = sources.map do |source|
        source_id = Integer(source.fetch("id"))
        value = public_fields(source, SOURCE_FIELDS)
        value["held_items"] = rows("SELECT i.*, s.xml_id AS parent_source_xml_id FROM held_items i JOIN source_descriptions s ON s.id = i.source_description_id WHERE i.source_description_id = #{source_id} ORDER BY i.source_order, i.id").map do |item|
          public_fields(item, ITEM_FIELDS).merge("source_xml_id" => item.fetch("parent_source_xml_id"))
        end
        value["relations"] = rows("SELECT r.*, owner.xml_id AS parent_source_xml_id, target.xml_id AS target_source_xml_id FROM source_relations r JOIN source_descriptions owner ON owner.id = r.source_description_id LEFT JOIN source_descriptions target ON target.id = r.target_source_description_id WHERE r.source_description_id = #{source_id} ORDER BY r.relation_order, r.token_order, r.id").map do |relation|
          public_fields(relation, RELATION_FIELDS).merge("source_xml_id" => relation.fetch("parent_source_xml_id"), "target_source_xml_id" => relation["target_source_xml_id"])
        end
        value
      end
      projected = doc["source_projection_version"] == "cnw_sources_v1" && !doc["source_projection_summary"].nil?
      {
        "document" => doc.slice("input_profile", "catalogue", "record_key", "root_xml_id", "committed_sha256"),
        "projection" => { "version" => doc["source_projection_version"], "summary" => projected ? doc["source_projection_summary"] : { "state" => "not_projected" } },
        "descriptions" => projected ? descriptions : []
      }
    end

    def state
      tables = DOMAIN_TABLES.to_h do |table|
        columns = rows("SELECT column_name, ordinal_position, data_type, udt_name, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public' AND table_name = #{quote(table)} ORDER BY ordinal_position")
        data = rows("SELECT * FROM #{table} ORDER BY id ASC")
        value = { "table" => table, "columns" => columns, "rows" => data }
        [table, { "count" => data.length, "sha256" => Digest::SHA256.hexdigest(JSON.generate(F2APIProbe.canonical(value))), "columns" => columns, "rows" => data }]
      end
      sequences = DOMAIN_TABLES.to_h do |table|
        name = rows("SELECT pg_get_serial_sequence(#{quote(table)}, 'id') AS sequence").first.fetch("sequence")
        value = if name
          quoted_name = name.split(".").map { |part| connection.quote_column_name(part) }.join(".")
          rows("SELECT last_value, is_called FROM #{quoted_name}").first
        end
        [table, { "sequence" => name, "state" => value }]
      end
      schema_metadata = {
        "schema_migrations" => rows("SELECT * FROM schema_migrations ORDER BY version"),
        "ar_internal_metadata" => rows("SELECT * FROM ar_internal_metadata ORDER BY key")
      }
      value = { "tables" => tables, "sequences" => sequences, "schema_metadata" => schema_metadata }
      value.merge("aggregate_sha256" => Digest::SHA256.hexdigest(JSON.generate(F2APIProbe.canonical(value))))
    end
  end
end
