# frozen_string_literal: true

# Standalone expectation/comparison support. Never calls application scopes,
# association readers, importer extraction helpers, or controller serializers.
require "json"
require "digest"
require "date"
require "time"

module F1APIProbe
  DOMAIN_TABLES = %w[composers works catalogue_identifiers movements instrumentations source_references performances external_references import_logs catalogue_documents work_titles work_classification_terms].freeze
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
      if value.is_a?(Array)
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
      F1APIProbe.json_value(decoded)
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

    def detail(work_id)
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

    def state
      tables = DOMAIN_TABLES.to_h do |table|
        columns = rows("SELECT column_name, ordinal_position, data_type, udt_name, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public' AND table_name = #{quote(table)} ORDER BY ordinal_position")
        data = rows("SELECT * FROM #{table} ORDER BY id ASC")
        value = { "table" => table, "columns" => columns, "rows" => data }
        [table, { "count" => data.length, "sha256" => Digest::SHA256.hexdigest(JSON.generate(F1APIProbe.canonical(value))), "columns" => columns, "rows" => data }]
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
      value.merge("aggregate_sha256" => Digest::SHA256.hexdigest(JSON.generate(F1APIProbe.canonical(value))))
    end
  end
end
