# frozen_string_literal: true

# F2-R1 copy: frozen F2 source facts/comparators retained; only target names and
# truthful held-item caption/absence assertions are added.
# Source -> SQL and SQL -> API/HTML evidence are separate. Only the guarded
# import action calls application code; expected facts use frozen XML or SQL.
require "fileutils"
require "cgi"
require_relative "f2r1_guard"
require_relative "f2r1_sql_probe_support"

module F2R1SourceCheck
  ORACLE_SHA256 = "991037f3dd3e34df7a4dfc2d89b34dddb31dab260807018c8ad25d89ca6f9425"
  FIELD_CONTRACT_SHA256 = "226bd7794098a608ad2a7f5e15a6debe6754e61f983cb6f4dae641af8db02ec6"
  F1_ORACLE_SHA256 = "1874d9b9488a38354240f884b2a42c746559965e5e0a78dce54668fe57d9f792"
  IMPORT_SEMANTIC_FILES = %w[
    app/services/mei/importer.rb app/services/mei/input_document.rb app/services/mei/source_projection.rb
    app/models/catalogue_document.rb app/models/work.rb app/models/import_log.rb
    app/models/source_description.rb app/models/held_item.rb app/models/source_relation.rb db/schema.rb
  ].freeze

  class Runner
    def initialize
      @app = File.realpath(ENV.fetch("F2R1_APP_ROOT"))
      @output = File.expand_path(ENV.fetch("F2R1_VALIDATION_OUTPUT"))
      raise "Fresh external F2-R1 output required" unless @output.start_with?("/private/tmp/www_f2r1_") && !@output.start_with?(@app + "/") && !File.exist?(@output) && !File.symlink?(@output)
      FileUtils.mkdir_p(@output, mode: 0o700)
      @result = { status: "IN_PROGRESS", started_utc: Time.now.utc.iso8601(6), build_id: ENV.fetch("F2R1_BUILD_ID"),
                  assertions: 0, checks: [], requests: [], evidence_scope: "six pinned development records only; no fixtures or reserved inputs" }
    end

    def sanitize(value)
      case value
      when Hash then value.transform_values { |item| sanitize(item) }
      when Array then value.map { |item| sanitize(item) }
      when String then value.gsub(@app, "$REVISED_APP").gsub(File.dirname(@app), "$F2R1_RUN")
      else value
      end
    end

    def save(name, value)
      File.open(File.join(@output, name), File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
        file.write(JSON.pretty_generate(sanitize(F2R1APIProbe.json_value(value))) + "\n")
      end
    end

    def assert(label, expected, actual, evidence_class: "protocol", **references)
      @result[:assertions] += 1
      row = { label: label, evidence_class: evidence_class, expected: expected, actual: actual, pass: expected == actual }.merge(references)
      @result[:checks] << row
      raise "Independent assertion failed: #{label}" unless row[:pass]
    end

    def read_frozen(env_key, expected_hash)
      path = File.realpath(ENV.fetch(env_key))
      raise "Reviewed input must be external F2-R1 scratch" unless path.start_with?("/private/tmp/www_f2r1_")
      raw = File.binread(path)
      assert(env_key + " frozen hash", expected_hash, Digest::SHA256.hexdigest(raw))
      JSON.parse(raw)
    end

    def semantic_files
      IMPORT_SEMANTIC_FILES.to_h do |name|
        path = File.join(@app, name)
        raise "Expected semantic source is missing or linked: #{name}" unless File.file?(path) && !File.symlink?(path)
        [name, Digest::SHA256.file(path).hexdigest]
      end
    end

    def prepare_inputs
      @oracle = read_frozen("F2R1_EXPECTATIONS_JSON", ORACLE_SHA256)
      read_frozen("F2R1_FIELD_CONTRACT_JSON", FIELD_CONTRACT_SHA256)
      @f1_oracle = read_frozen("F2R1_F1_EXPECTATIONS_JSON", F1_ORACLE_SHA256)
      @records = @oracle.fetch("development_records")
      assert("approved six source identities", ["417", "277", "63", "17", "45", "Coll. 27"], @records.map { |record| record.dig("logical_identity", "record_key") })
      @source_dir = File.realpath(ENV.fetch("F2R1_SOURCE_DIR"))
      raise "Source directory must be external F2-R1 scratch" unless @source_dir.start_with?("/private/tmp/www_f2r1_")
      expected_names = @records.map { |record| record.fetch("source_filename") }
      files = Dir.glob(File.join(@source_dir, "**", "*.{xml,mei}")).sort
      assert("exact six source filenames", expected_names.sort, files.map { |path| File.basename(path) }.sort)
      @input_manifest = @records.map do |record|
        filename = record.fetch("source_filename")
        raise "Source filename must be a basename" unless File.basename(filename) == filename
        path = File.join(@source_dir, filename)
        raise "Linked source refused" if File.symlink?(path)
        assert(filename + " bytes", record.fetch("bytes"), File.size(path))
        assert(filename + " hash", record.fetch("sha256"), Digest::SHA256.file(path).hexdigest)
        record.slice("source_filename", "bytes", "sha256", "logical_identity")
      end
      @result[:oracle_sha256] = ORACLE_SHA256
      @result[:field_contract_sha256] = FIELD_CONTRACT_SHA256
      @result[:source_manifest] = @input_manifest
      @result[:import_semantic_files] = semantic_files
    end

    def import_or_continue
      if ENV["F2R1_IMPORT_EVIDENCE"]
        path = File.realpath(ENV.fetch("F2R1_IMPORT_EVIDENCE"))
        raise "Prior import proof must be external F2-R1 scratch" unless path.start_with?("/private/tmp/www_f2r1_")
        previous = JSON.parse(File.read(path))
        assert("prior proof kind/status", ["F2R1_SIX_SOURCE_IMPORT_PROOF", "PASS"], previous.values_at("kind", "status"))
        assert("prior import target", @guard.target.slice("database", "username", "host", "port", "data_directory"), previous.fetch("target"))
        assert("prior import pinned inputs", @input_manifest, previous.fetch("source_manifest"))
        assert("prior import source oracle", ORACLE_SHA256, previous.fetch("oracle_sha256"))
        assert("import semantic files unchanged for observation continuation", @result[:import_semantic_files], previous.fetch("import_semantic_files"))
        assert("prior six-source success", [6, 6, 0, []], previous.fetch("import").values_at("files_seen", "successes", "failures", "run_errors"))
        @result[:import] = previous.fetch("import")
        @result[:import_execution] = { invocations_this_run: 0, mode: "explicit observation-only continuation", previous_evidence: path, previous_evidence_sha256: Digest::SHA256.file(path).hexdigest }
      else
        counts = F2R1APIProbe::DOMAIN_TABLES.to_h { |table| [table, @facts.rows("SELECT count(*) AS count FROM #{table}").first.fetch("count")] }
        assert("fresh API target domain tables", counts.transform_values { 0 }, counts)
        imported = @guard.with_phase("six_source_import") { Mei::Importer.new(directory: @source_dir, input_profile: "official_cnw_v401").call }
        @result[:import] = { files_seen: imported.files_seen, successes: imported.successes, failures: imported.failures, run_errors: imported.run_errors }
        @result[:import_execution] = { invocations_this_run: 1, mode: "fresh six-source import" }
        outcomes = [imported.files_seen, imported.successes, imported.failures, imported.run_errors]
        proof = { kind: "F2R1_SIX_SOURCE_IMPORT_PROOF", status: outcomes == [6, 6, 0, []] ? "PASS" : "FAIL", recorded_utc: Time.now.utc.iso8601(6),
                  target: @guard.target.slice("database", "username", "host", "port", "data_directory"), import: @result[:import], source_manifest: @input_manifest,
                  oracle_sha256: ORACLE_SHA256, import_semantic_files: @result[:import_semantic_files], guard: @guard.summary }
        save("import_proof.json", proof)
        assert("six input outcomes", [6, 6, 0, []], outcomes, evidence_class: "import_execution")
      end
    end

    def source_to_sql
      assert("document/work cardinality", [6, 6], %w[catalogue_documents works].map { |table| @facts.rows("SELECT count(*) AS count FROM #{table}").first.fetch("count") }, evidence_class: "source_to_SQL")
      assert("source/item/relation cardinality", [25, 22, 24], %w[source_descriptions held_items source_relations].map { |table| @facts.rows("SELECT count(*) AS count FROM #{table}").first.fetch("count") }, evidence_class: "source_to_SQL")
      ownership_sql = <<~SQL
        SELECT
          (SELECT count(*) FROM held_items i JOIN source_descriptions s ON s.id=i.source_description_id WHERE i.catalogue_document_id<>s.catalogue_document_id) AS wrong_item_parent,
          (SELECT count(*) FROM source_relations r JOIN source_descriptions s ON s.id=r.source_description_id WHERE r.catalogue_document_id<>s.catalogue_document_id) AS wrong_relation_parent,
          (SELECT count(*) FROM source_relations r JOIN source_descriptions s ON s.id=r.target_source_description_id WHERE r.catalogue_document_id<>s.catalogue_document_id) AS wrong_source_target,
          (SELECT count(*) FROM source_relations r JOIN works w ON w.id=r.target_work_id WHERE r.catalogue_document_id<>w.catalogue_document_id) AS wrong_work_target
      SQL
      ownership = @facts.rows(ownership_sql).first
      assert("direct SQL same-document ownership", ownership.transform_values { 0 }, ownership, evidence_class: "source_to_SQL")
      @work_ids = {}
      @records.each_with_index do |record, index|
        key = record.fetch("logical_identity").fetch("record_key")
        docs = @facts.rows("SELECT * FROM catalogue_documents WHERE input_profile='official_cnw_v401' AND catalogue='CNW' AND record_key=#{@facts.quote(key)}")
        assert(key + " unique document", 1, docs.length, evidence_class: "source_to_SQL")
        works = @facts.rows("SELECT * FROM works WHERE catalogue_document_id=#{Integer(docs.first.fetch('id'))}")
        assert(key + " unique work", 1, works.length, evidence_class: "source_to_SQL")
        work = works.first
        @work_ids[key] = work.fetch("id")
        actual = @facts.catalogue_sources(work)
        name = "source_sql_#{key.gsub(/[^A-Za-z0-9]/, '_')}.json"
        save(name, actual)
        differences = F2R1APIProbe.deep_compare(record.fetch("expected_catalogue_sources"), actual)
        save("source_comparison_#{index}.json", { expected_ref: "f2_source_expectations_v1.json#/development_records/#{index}/expected_catalogue_sources", actual_ref: name, differences: differences })
        assert(key + " full frozen source projection", [], differences, evidence_class: "source_to_SQL", expected_ref: "f2_source_expectations_v1.json#/development_records/#{index}/expected_catalogue_sources", observed_ref: name)
        f1 = @f1_oracle.fetch("development_records").find { |value| value.dig("logical_identity", "record_key") == key }
        raise "Missing independent F1 expectation" unless f1
        assert(key + " F1 heading/genre unchanged", [f1.fetch("required_heading"), f1.fetch("required_derived_genre")], work.values_at("title", "genre"), evidence_class: "F1_source_regression")
        titles = @facts.rows("SELECT text,raw_text,source_type,language,xml_id,source_order,locator,source_attributes AS attributes FROM work_titles WHERE work_id=#{Integer(work.fetch('id'))} ORDER BY source_order,id")
        terms = @facts.rows("SELECT text,raw_text,xml_id,source_order,locator,source_attributes AS attributes,classification_metadata AS classification,term_list_metadata AS term_lists FROM work_classification_terms WHERE work_id=#{Integer(work.fetch('id'))} ORDER BY source_order,id")
        assert(key + " all F1 title rows unchanged", f1.fetch("titles"), titles, evidence_class: "F1_source_regression")
        assert(key + " all F1 term rows unchanged", f1.fetch("classification_terms"), terms, evidence_class: "F1_source_regression")
      end
    end

    def request(label, path, expected: nil, html: false)
      row = { label: label, path: path, evidence_class: html ? "HTML" : "SQL_to_API", started_utc: Time.now.utc.iso8601(6) }
      @result[:requests] << row
      @guard.with_phase(label) { @session.get(path, headers: { "Accept" => html ? "text/html" : "application/json" }) }
      response = @session.response
      body = response.body.to_s
      row.merge!(status: response.status, content_type: response.content_type, raw_sha256: Digest::SHA256.hexdigest(body))
      File.open(File.join(@output, label + (html ? ".html" : ".json")), "wx", 0o600) { |file| file.write(sanitize(body)) }
      events = @guard.events_for(label).select { |event| event[:kind] == "sql" && event[:identity] && event[:sql].to_s.match?(/\bFROM\s+"?works"?/i) }
      row[:live_work_query_identities] = events.map { |event| event[:identity] }.uniq
      assert(label + " HTTP status", 200, response.status, evidence_class: row[:evidence_class])
      assert(label + " response media type", html ? "text/html" : "application/json", response.media_type, evidence_class: row[:evidence_class])
      assert(label + " live request identity", true, !events.empty?, evidence_class: "request_guard")
      actual = html ? Nokogiri::HTML(body) : JSON.parse(body)
      unless html
        comparison = expected.is_a?(Array) ? F2R1APIProbe.compare_index(expected, actual) : { "diffs" => F2R1APIProbe.compare_work(expected, actual) }
        comparison["pass"] = comparison["diffs"].empty?
        row[:comparison] = comparison
        assert(label + " independent SQL/API agreement", true, comparison["pass"], evidence_class: "SQL_to_API", observed_ref: label + ".json")
      end
      actual
    rescue StandardError => error
      row[:exception] = { class: error.class.name, message: sanitize(error.message.to_s[0, 2000]) }
      raise
    ensure
      row[:finished_utc] = Time.now.utc.iso8601(6) if row
    end

    def own_field_nodes(scope, field)
      scope.css(%([data-field="#{field}"])).select do |node|
        ancestors = node.ancestors.take_while { |parent| parent != scope }
        !ancestors.any? { |parent| parent["data-item-xml-id"] || parent["data-relation-order"] || parent["data-source-xml-id"] }
      end
    end

    def normalized_text(text) = text.to_s.gsub(/[\x20\x09\x0a\x0d]+/, " ").strip

    def html_value_field(prefix, scope, field, values)
      fields = own_field_nodes(scope, field)
      assert(prefix + " one owned " + field + " field", 1, fields.length, evidence_class: "HTML")
      nodes = fields.first.css("ol.plain-list > li[data-value-order]")
      expected = values.map do |value|
        text = [value["text"], value.fetch("attributes", {})["target"], value.fetch("attributes", {})["href"]].find { |item| !normalized_text(item).empty? }
        { order: value.fetch("source_order").to_s, text: normalized_text(text || "Not supplied") }
      end
      actual = nodes.map { |node| { order: node["data-value-order"], text: normalized_text(node.at_css("span.source-value")&.text) } }
      assert(prefix + " visible ordered " + field + " values", expected, actual, evidence_class: "HTML")
      values.zip(nodes).each do |value, node|
        next unless value["element"] == "title"
        expected_label = "Type: #{value['source_type'] || 'Untyped'}; language: #{value['language'] || 'Not supplied'}"
        assert(prefix + " title type/language " + value.fetch("source_order").to_s, expected_label, normalized_text(node.at_css("span.muted")&.text), evidence_class: "HTML")
      end
    end

    def html_sources(key, html, expected)
      section = html.at_css("#catalogue-sources")
      assert(key + " source section exists", true, !section.nil?, evidence_class: "HTML")
      assert(key + " source section labelled", true, section.text.include?("Source descriptions in this catalogue record"), evidence_class: "HTML")
      assert(key + " projection state", expected.dig("projection", "summary", "state"), section["data-projection-state"], evidence_class: "HTML")
      source_nodes = section.css("details[data-source-xml-id]")
      assert(key + " source identity order", expected.fetch("descriptions").map { |row| row.fetch("xml_id") }, source_nodes.map { |node| node["data-source-xml-id"] }, evidence_class: "HTML")
      expected.fetch("descriptions").zip(source_nodes).each do |source, node|
        prefix = key + " " + source.fetch("xml_id")
        assert(prefix + " source state", source.fetch("state"), node["data-source-state"], evidence_class: "HTML")
        # F2-R1 additions inspect only this source's direct disclosure/paragraphs.
        # Supplied-node completeness comes from the exact document count, never
        # the represented array or truncated issue list. The source oracle is unchanged.
        caption = normalized_text(node.element_children.find { |child| child.name == "summary" }&.text)
        represented_count = source.fetch("held_items").length
        assert(prefix + " explicitly represented held-item caption", true,
          caption.include?(" — #{represented_count} represented item nodes; "), evidence_class: "HTML_availability_R1")
        assert(prefix + " caption does not claim represented count is total supplied nodes", false,
          caption.match?(/\b#{Regexp.escape(represented_count.to_s)} item nodes\b/), evidence_class: "HTML_availability_R1")
        paragraphs = node.element_children.select { |child| child.name == "p" }.map { |child| normalized_text(child.text) }
        absence = "No held-item nodes are supplied for this description."
        unsupported = expected.dig("projection", "summary", "unsupported_items")
        justified_absence = source.fetch("held_items").empty? && unsupported == 0
        assert(prefix + " supplied-node absence only with explicit document zero", justified_absence,
          paragraphs.include?(absence), evidence_class: "HTML_availability_R1")
        if source.fetch("held_items").empty? && unsupported != 0
          assert(prefix + " neutral represented-empty message", true,
            paragraphs.any? { |text| text.include?("No held-item descriptions are represented here.") }, evidence_class: "HTML_availability_R1")
          if unsupported.is_a?(Integer) && unsupported.positive?
            assert(prefix + " unsupported items are attributed to catalogue record", true,
              paragraphs.any? { |text| text.include?("This catalogue record contains unsupported item nodes") && text.include?("Unsupported or unresolved details") }, evidence_class: "HTML_availability_R1")
          else
            assert(prefix + " missing availability count remains unknown", true,
              paragraphs.any? { |text| text.match?(/unknown|cannot establish|cannot be established/i) }, evidence_class: "HTML_availability_R1")
          end
        end
        %w[titles classification_terms publication physical_description notes identifiers links].each do |field|
          html_value_field(prefix, node, field, source.fetch(field))
        end
        items = node.css("section[data-item-xml-id]")
        assert(prefix + " exact held-item parents/order", source.fetch("held_items").map { |row| row.fetch("xml_id") }, items.map { |item| item["data-item-xml-id"] }, evidence_class: "HTML")
        source.fetch("held_items").zip(items).each do |item, item_node|
          item_prefix = prefix + " " + item.fetch("xml_id")
          assert(item_prefix + " item state", item.fetch("state"), item_node["data-item-state"], evidence_class: "HTML")
          { "identifiers" => "item-identifiers", "physical_description" => "item-physical-description", "links" => "item-links" }.each do |field, hook|
            html_value_field(item_prefix, item_node, hook, item.fetch(field))
          end
          locations = item_node.css("section[data-location-order]")
          assert(item_prefix + " location order", item.fetch("physical_locations").map { |location| location.fetch("source_order").to_s }, locations.map { |location| location["data-location-order"] }, evidence_class: "HTML")
          item.fetch("physical_locations").zip(locations).each do |location, location_node|
            location_prefix = item_prefix + " location " + location.fetch("source_order").to_s
            html_value_field(location_prefix, location_node, "location-identifiers", location.fetch("identifiers"))
            repositories = location_node.css("section[data-repository-order]")
            assert(location_prefix + " repository order", location.fetch("repositories").map { |repository| repository.fetch("source_order").to_s }, repositories.map { |repository| repository["data-repository-order"] }, evidence_class: "HTML")
            location.fetch("repositories").zip(repositories).each do |repository, repository_node|
              %w[identifiers names links].each do |field|
                html_value_field(location_prefix + " repository " + repository.fetch("source_order").to_s, repository_node, "repository-" + field, repository.fetch(field))
              end
            end
          end
          assert(item_prefix + " location identifier label", true, item_node.text.include?("Location identifier"), evidence_class: "HTML") if item.fetch("availability").fetch("location_identifiers") == "present"
        end
        relations = node.css("li[data-relation-order][data-token-order]")
        assert(prefix + " relation node/token order", source.fetch("relations").map { |r| [r.fetch("relation_order").to_s, r.fetch("token_order").to_s] }, relations.map { |r| [r["data-relation-order"], r["data-token-order"]] }, evidence_class: "HTML")
        source.fetch("relations").zip(relations).each do |relation, relation_node|
          assert(prefix + " relation state " + relation.fetch("relation_order").to_s, relation.fetch("resolution_state"), relation_node["data-resolution-state"], evidence_class: "HTML")
          assert(prefix + " explicit expression target " + relation.fetch("relation_order").to_s, true, relation_node.text.include?(relation.fetch("expression_context").fetch("xml_id")), evidence_class: "HTML") if relation["expression_context"]
        end
        if source.fetch("relations").none? { |r| r["resolution_state"] == "resolved_expression" }
          assert(prefix + " unspecified relationship label", true, node.text.downcase.include?("relationship unspecified"), evidence_class: "HTML")
        end
      end
      section.css("a[href]").each do |link|
        href = link["href"]
        target = href.start_with?("#") && section.css("[id]").find { |node| node["id"] == href.delete_prefix("#") }
        assert(key + " only existing local source anchors", true, !!target, evidence_class: "HTML")
      end
      assert(key + " source absence label", true, section.text.include?("No source-description nodes are supplied by this record."), evidence_class: "HTML") if expected.dig("projection", "summary", "state") == "absent_in_source"
    end

    def run_requests
      require "action_dispatch/testing/integration"
      @session = ActionDispatch::Integration::Session.new(Rails.application)
      @session.host! "www.example.com"
      index = @facts.index
      details = @work_ids.to_h { |key, id| [key, @facts.detail(id)] }
      save("independent_sql_expectations.json", { index: index, details: details })
      before = @guard.with_phase("state_before_requests") { @facts.state }
      save("state_before_requests.json", before)
      request("index", "/api/works", expected: index)
      responses = {}
      details.each do |key, expected|
        label = key.gsub(/[^A-Za-z0-9]/, "_")
        responses[key] = request("detail_" + label, "/api/works/#{@work_ids.fetch(key)}", expected: expected)
        assert(key + " no absolute ingest paths in new JSON", false, JSON.generate(responses[key].fetch("catalogue_sources")).match?(%r{/(?:private/|Users/|tmp/)}), evidence_class: "SQL_to_API")
        html = request("html_" + label, "/works/#{@work_ids.fetch(key)}", html: true)
        assert(key + " F1 heading preserved", expected.fetch("title"), html.at_css("h1").text.strip, evidence_class: "F1_HTML_regression")
        html_sources(key, html, expected.fetch("catalogue_sources"))
      end
      f1_277 = @f1_oracle.fetch("development_records").find { |record| record.dig("logical_identity", "record_key") == "277" }
      f1_277.fetch("titles").select { |title| %w[alternative uniform].include?(title["source_type"]) }.each_with_index do |title, order|
        expected = index.select { |row| row.fetch("id") == @work_ids.fetch("277") }
        query = "q=" + CGI.escape(title.fetch("text"))
        request("variant_api_#{order}", "/api/works?#{query}", expected: expected)
        html = request("variant_html_#{order}", "/works?#{query}", html: true)
        assert("F1 variant filtered HTML #{order}", ["/works/#{@work_ids.fetch('277')}"], html.css('table.works-table a[href^="/works/"]').map { |node| node["href"] }, evidence_class: "F1_HTML_regression")
      end
      expected = index.select { |row| row.fetch("id") == @work_ids.fetch("63") }
      request("second_term_api", "/api/works?genre=Chamber%20music", expected: expected)
      html = request("second_term_html", "/works?genre=Chamber%20music", html: true)
      assert("F1 second term HTML", ["/works/#{@work_ids.fetch('63')}"], html.css('table.works-table a[href^="/works/"]').map { |node| node["href"] }, evidence_class: "F1_HTML_regression")
      changed = Marshal.load(Marshal.dump(details.fetch("63")))
      item = changed.fetch("catalogue_sources").fetch("descriptions").find { |row| !row.fetch("held_items").empty? }.fetch("held_items").first
      item["source_xml_id"] += "_DELIBERATE_WRONG_PARENT"
      diffs = F2R1APIProbe.compare_work(changed, responses.fetch("63"))
      assert("same comparator rejects changed parent identity", 1, diffs.length, evidence_class: "comparator_negative_control")
      assert("negative difference identifies item parent", true, diffs.first.fetch(:path).end_with?(".held_items[0].source_xml_id"), evidence_class: "comparator_negative_control")
      @result[:comparator_negative_control] = { status: "PASS", response_changed: false, differences: diffs }
    ensure
      if before && @guard.summary[:refusals].empty?
        after = @guard.with_phase("state_after_requests") { @facts.state }
        save("state_after_requests.json", after)
        assert("all fifteen domain tables/sequences/schema unchanged by requests", true, before == after,
          evidence_class: "request_state_preservation", before_ref: "state_before_requests.json", after_ref: "state_after_requests.json",
          before_sha256: before.fetch("aggregate_sha256"), after_sha256: after.fetch("aggregate_sha256"))
      end
    end

    def run
      prepare_inputs
      @guard = F2R1Guard.boot!
      @guard.schema_current!
      @result[:wrong_identity_controls] = @guard.run_negative_controls!
      @facts = F2R1APIProbe::SQLFacts.new { ActiveRecord::Base.connection }
      import_or_continue
      source_to_sql
      run_requests
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
      puts JSON.pretty_generate(sanitize(@result.reject { |key, _value| %i[checks requests].include?(key) }))
    end

    def exit_code = @result[:status] == "PASS" ? 0 : 1
  end
end

probe = F2R1SourceCheck::Runner.new
probe.run
exit probe.exit_code
