# frozen_string_literal: true

# Independent source -> SQL -> API checks. Expected values never use Work scopes,
# associations, importer extraction helpers or controller/helper serializers.
require "fileutils"
require "cgi"
require_relative "f1_guard"
require_relative "f1_sql_probe_support"

module F1SourceCheck
  class Facts < F1APIProbe::SQLFacts
    def timestamp(value)
      value && Time.iso8601(value).iso8601(3)
    end

    def detail(work_id)
      base = super
      work = rows("SELECT * FROM works WHERE id = #{Integer(work_id)}").fetch(0)
      doc = rows("SELECT * FROM catalogue_documents WHERE id = #{Integer(work.fetch('catalogue_document_id'))}").fetch(0)
      titles = rows("SELECT text, raw_text, source_type, language, xml_id, source_order, locator, source_attributes AS attributes FROM work_titles WHERE work_id = #{Integer(work_id)} ORDER BY source_order, id")
      titles.each { |row| row["selected_for_display"] = row["source_order"] == work["display_title_order"] }
      terms = rows("SELECT text, raw_text, xml_id, source_order, locator, source_attributes AS attributes, classification_metadata, term_list_metadata FROM work_classification_terms WHERE work_id = #{Integer(work_id)} ORDER BY source_order, id")
      attempts = rows("SELECT * FROM import_logs WHERE catalogue_document_id = #{Integer(doc.fetch('id'))} ORDER BY imported_at DESC, id DESC")
      latest = attempts.first
      successful = attempts.find { |row| row["status"] == "success" }
      warning_rows = latest ? Array(latest["warnings"]) : []
      warning_rows.each do |warning|
        raise "Source-run warning needs a separately declared diagnostic oracle" unless warning.is_a?(String) && warning == warning.lines.first.to_s.strip && warning.length <= 512 && !warning.match?(%r{<|://|/(?:Users|private|tmp)/})
      end
      visible_warnings = warning_rows.first(20)
      visible_warnings << "Additional warnings are retained in the local import log." if warning_rows.length > 20
      selected = titles.find { |row| row["source_order"] == work["display_title_order"] }
      base.merge(
        "titles" => titles, "classification_terms" => terms,
        "display_title_policy" => {
          "name" => "main_untyped_uniform_alternative_subordinate_v1",
          "selection_reason" => work["display_title_reason"], "source_order" => work["display_title_order"],
          "xml_id" => selected && selected["xml_id"], "subordinate_fallback" => selected && selected["source_type"] == "subordinate"
        },
        "latest_import_attempt" => latest && {
          "id" => latest["id"], "status" => latest["status"], "imported_at" => timestamp(latest["imported_at"]),
          # This source run requires success attempts with controlled bounded
          # warnings. Failure redaction has separate synthetic integrations.
          "error_message" => latest["error_message"], "warnings" => visible_warnings,
          "attempted_profile" => latest["attempted_profile"], "attempted_catalogue" => latest["attempted_catalogue"],
          "attempted_record_key" => latest["attempted_record_key"], "attempted_sha256" => latest["attempted_sha256"],
          "previous_committed_sha256" => latest["previous_committed_sha256"]
        },
        "last_successful_import" => successful && {
          "id" => successful["id"], "imported_at" => timestamp(successful["imported_at"]),
          "input_profile" => successful["attempted_profile"], "catalogue" => successful["attempted_catalogue"],
          "record_key" => successful["attempted_record_key"], "committed_sha256" => successful["attempted_sha256"]
        },
        "availability" => { "status" => "official", "input_profile" => doc["input_profile"],
          "titles" => titles.empty? ? "missing" : "present", "classification_terms" => terms.empty? ? "missing" : "present" }
      )
    end
  end

  class Runner
    def initialize
      @app = File.realpath(ENV.fetch("F1_APP_ROOT"))
      @output = File.expand_path(ENV.fetch("F1_VALIDATION_OUTPUT"))
      raise "Fresh external F1 output directory required" unless @output.start_with?("/private/tmp/www_f1_") && !@output.start_with?(@app + "/") && !File.exist?(@output)
      FileUtils.mkdir_p(@output)
      @result = { status: "IN_PROGRESS", started_utc: Time.now.utc.iso8601(6), source_checks: [], requests: [], assertions: 0 }
    end

    def sanitize(value)
      case value
      when Hash then value.transform_values { |item| sanitize(item) }
      when Array then value.map { |item| sanitize(item) }
      when String then value.gsub(@app, "$REVISED_APP").gsub(File.dirname(@app), "$F1_RUN")
      else value
      end
    end

    def save(name, value)
      File.write(File.join(@output, name), JSON.pretty_generate(sanitize(F1APIProbe.json_value(value))) + "\n")
    end

    def assert(label, expected, actual)
      @result[:assertions] += 1
      row = { label: label, expected: expected, actual: actual, pass: expected == actual }
      @result[:source_checks] << row
      raise "Independent assertion failed: #{label}" unless row[:pass]
    end

    def request(label, path, expected: nil, html: false)
      row = { label: label, path: path, evidence_class: html ? "HTML" : "database_to_API", started_utc: Time.now.utc.iso8601(6) }
      @guard.with_phase(label) { @session.get(path, headers: { "Accept" => html ? "text/html" : "application/json" }) }
      response = @session.response
      body = response.body.to_s
      row.merge!(status: response.status, content_type: response.content_type, raw_sha256: Digest::SHA256.hexdigest(body))
      events = @guard.events_for(label).select { |event| event[:kind] == "sql" && event[:identity] && event[:sql].to_s.match?(/\bFROM\s+"?works"?/i) }
      row[:live_work_query_identities] = events.map { |event| event[:identity] }.uniq
      File.write(File.join(@output, label + (html ? ".html" : ".json")), sanitize(body))
      @result[:requests] << row
      assert(label + " HTTP status", 200, response.status)
      assert(label + " live request identity", true, !events.empty?)
      actual = html ? Nokogiri::HTML(body) : JSON.parse(body)
      unless html
        comparison = if expected.is_a?(Array)
          F1APIProbe.compare_index(expected, actual)
        else
          differences = F1APIProbe.compare_work(expected, actual)
          { "pass" => differences.empty?, "diffs" => differences }
        end
        row[:comparison] = comparison
        assert(label + " independent SQL/API agreement", true, comparison["pass"])
      end
      actual
    ensure
      row[:finished_utc] = Time.now.utc.iso8601(6) if row
    end

    def run
      oracle_path = File.realpath(ENV.fetch("F1_EXPECTATIONS_JSON"))
      oracle_hash = ENV.fetch("F1_EXPECTATIONS_SHA256")
      assert("frozen source oracle hash", oracle_hash, Digest::SHA256.file(oracle_path).hexdigest)
      oracle = JSON.parse(File.read(oracle_path))
      records = oracle.fetch("development_records")
      assert("approved source count", 6, records.length)
      source_dir = File.realpath(ENV.fetch("F1_SOURCE_DIR"))
      raise "Source input must be external F1 scratch" unless source_dir.start_with?("/private/tmp/www_f1_")
      files = Dir.glob(File.join(source_dir, "**", "*.{xml,mei}")).sort
      assert("exact approved source names", records.map { |row| row.fetch("source_filename") }.sort, files.map { |path| File.basename(path) }.sort)
      records.each do |record|
        path = File.join(source_dir, record.fetch("source_filename"))
        raise "Symlink source refused" if File.symlink?(path)
        assert(record["source_filename"] + " bytes", record.fetch("bytes"), File.size(path))
        assert(record["source_filename"] + " SHA256", record.fetch("sha256"), Digest::SHA256.file(path).hexdigest)
      end
      @guard = F1Guard.boot!
      @guard.schema_current!
      @result[:wrong_identity_controls] = @guard.run_negative_controls!
      @facts = Facts.new { ActiveRecord::Base.connection }
      if ENV["F1_IMPORT_EVIDENCE"]
        previous_path = File.realpath(ENV.fetch("F1_IMPORT_EVIDENCE"))
        raise "Prior import evidence must be retained external F1 scratch" unless previous_path.start_with?("/private/tmp/www_f1_")
        previous = JSON.parse(File.read(previous_path))
        assert("prior import target matches current dedicated target", @guard.target.fetch("database"), previous.dig("guard", "target", "database"))
        assert("prior six-source import completed", [6, 6, 0, []], previous.fetch("import").values_at("files_seen", "successes", "failures", "run_errors"))
        @result[:import] = previous.fetch("import")
        @result[:import_execution] = { invocations_this_run: 0, mode: "explicit observation-only continuation", previous_evidence: previous_path, previous_evidence_sha256: Digest::SHA256.file(previous_path).hexdigest }
      else
        assert("fresh API domain works", 0, @facts.rows("SELECT count(*) AS count FROM works").first.fetch("count"))
        import = @guard.with_phase("six_source_import") { Mei::Importer.new(directory: source_dir, input_profile: "official_cnw_v401").call }
        @result[:import] = { files_seen: import.files_seen, successes: import.successes, failures: import.failures, run_errors: import.run_errors }
        @result[:import_execution] = { invocations_this_run: 1, mode: "fresh six-source import" }
        assert("six real input outcomes", [6, 6, 0, []], [import.files_seen, import.successes, import.failures, import.run_errors])
      end
      assert("one document/work per source", [6, 6], [@facts.rows("SELECT count(*) AS count FROM catalogue_documents").first.fetch("count"), @facts.rows("SELECT count(*) AS count FROM works").first.fetch("count")])
      @work_ids = {}
      records.each do |record|
        key = record.fetch("logical_identity").fetch("record_key")
        docs = @facts.rows("SELECT * FROM catalogue_documents WHERE input_profile='official_cnw_v401' AND catalogue='CNW' AND record_key=#{@facts.quote(key)}")
        assert(key + " unique document", 1, docs.length)
        doc = docs.first
        { "committed_sha256" => record["sha256"], "raw_record_identifier" => record["raw_record_identifier"],
          "identifier_attributes" => record.dig("cnw_identifier", "attributes"), "root_xml_id" => record["root_xml_id"],
          "mei_namespace" => record["namespace"], "mei_version" => record["declared_mei_version"], "origin_relative_name" => record["source_filename"] }.each do |field, value|
          assert(key + " document " + field, value, doc[field])
        end
        works = @facts.rows("SELECT * FROM works WHERE catalogue_document_id=#{Integer(doc.fetch('id'))}")
        assert(key + " unique owned work", 1, works.length)
        work = works.first; id = work.fetch("id"); @work_ids[key] = id
        { "title" => record["required_heading"], "genre" => record["required_derived_genre"], "source_identifier" => record["work_xml_id"],
          "display_title_order" => record["required_heading_source_order"], "display_title_reason" => record["required_heading_selection_reason"] }.each { |field, value| assert(key + " work " + field, value, work[field]) }
        titles = @facts.rows("SELECT text,raw_text,source_type,language,xml_id,source_order,locator,source_attributes AS attributes FROM work_titles WHERE work_id=#{Integer(id)} ORDER BY source_order,id")
        assert(key + " all source title rows", record.fetch("titles"), titles)
        terms = @facts.rows("SELECT text,raw_text,xml_id,source_order,locator,source_attributes AS attributes,classification_metadata AS classification,term_list_metadata AS term_lists FROM work_classification_terms WHERE work_id=#{Integer(id)} ORDER BY source_order,id")
        assert(key + " all source classification rows", record.fetch("classification_terms"), terms)
      end
      require "action_dispatch/testing/integration"
      @session = ActionDispatch::Integration::Session.new(Rails.application)
      @session.host! "www.example.com"
      expected_index = @facts.index
      details = @work_ids.to_h { |key, id| [key, @facts.detail(id)] }
      save("independent_sql_expectations.json", { index: expected_index, details: details })
      before = @guard.with_phase("state_before_requests") { @facts.state }
      save("state_before_requests.json", before)
      request("index", "/api/works", expected: expected_index)
      details.each do |key, expected|
        id = @work_ids.fetch(key); label = key.gsub(/[^A-Za-z0-9]/, "_")
        actual = request("detail_" + label, "/api/works/#{id}", expected: expected)
        public_additions = actual.slice("titles", "classification_terms", "display_title_policy", "latest_import_attempt", "last_successful_import", "availability")
        assert(label + " new fields omit absolute local paths", false, JSON.generate(public_additions).match?(%r{/(?:private/|Users/|tmp/)}))
        html = request("html_" + label, "/works/#{id}", html: true)
        assert(label + " HTML heading", expected.fetch("title"), html.at_css("h1").text.strip)
        expected.fetch("titles").each { |title| assert(label + " HTML title " + title.fetch("source_order").to_s, true, html.text.include?(title.fetch("text"))) }
        expected.fetch("classification_terms").each { |term| assert(label + " HTML term " + term.fetch("source_order").to_s, true, html.text.include?(term.fetch("text"))) }
      end
      cnw277 = records.find { |row| row.dig("logical_identity", "record_key") == "277" }
      cnw277.fetch("titles").select { |title| %w[alternative uniform].include?(title["source_type"]) }.each_with_index do |title, index|
        value = title.fetch("text"); encoded = CGI.escape(value)
        expected = expected_index.select { |row| row.fetch("id") == @work_ids.fetch("277") }
        request("variant_api_#{index}", "/api/works?q=#{encoded}", expected: expected)
        html = request("variant_html_#{index}", "/works?q=#{encoded}", html: true)
        ids = html.css('a[href^="/works/"]').map { |a| a["href"] }.uniq
        assert("variant HTML unique work #{index}", ["/works/#{@work_ids.fetch('277')}"], ids)
      end
      expected = expected_index.select { |row| row.fetch("id") == @work_ids.fetch("63") }
      request("second_term_api", "/api/works?genre=Chamber%20music", expected: expected)
      html = request("second_term_html", "/works?genre=Chamber%20music", html: true)
      assert("second-term HTML unique work", ["/works/#{@work_ids.fetch('63')}"], html.css('a[href^="/works/"]').map { |a| a["href"] }.uniq)
      after = @guard.with_phase("state_after_requests") { @facts.state }
      save("state_after_requests.json", after)
      assert("bounded twelve-table request state unchanged", before, after)
      actual = JSON.parse(File.read(File.join(@output, "detail_63.json")))
      changed = Marshal.load(Marshal.dump(details.fetch("63")))
      changed["title"] += " [DELIBERATE NEGATIVE CONTROL]"
      diffs = F1APIProbe.compare_work(changed, actual)
      assert("same comparator rejects changed expected title", ["$.title"], diffs.map { |row| row.fetch(:path) })
      @result[:comparator_negative_control] = { status: "PASS", differences: diffs, response_changed: false }
      @guard.ensure_no_refusals!
      @result[:status] = "PASS"
    rescue StandardError => error
      @result[:status] = "FAIL"
      @result[:error] = { class: error.class.name, message: sanitize(error.message.to_s[0, 2000]) }
    ensure
      @result[:ended_utc] = Time.now.utc.iso8601(6)
      @result[:guard] = @guard.summary if @guard
      save("sql_statements.json", @facts.statements) if @facts
      save("result.json", @result)
      puts JSON.pretty_generate(sanitize(@result.reject { |key, _| key == :source_checks || key == :requests }))
    end

    def exit_code = @result[:status] == "PASS" ? 0 : 1
  end
end

probe = F1SourceCheck::Runner.new
probe.run
exit probe.exit_code
