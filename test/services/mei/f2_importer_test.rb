require "test_helper"
require "tmpdir"
require "digest"

module Mei
  class F2ImporterTest < ActiveSupport::TestCase
    setup do
      SourceRelation.delete_all
      HeldItem.delete_all
      SourceDescription.delete_all
      ImportLog.delete_all
      Work.destroy_all
      CatalogueDocument.delete_all
      Composer.destroy_all
    end

    test "fresh source projection and current-byte reimports retain all semantic rows" do
      in_directory do |original|
        in_directory do |relocated|
          contents = xml
          assert import(original, contents).success?
          document = CatalogueDocument.sole
          facts = semantic_rows(document)
          assert_equal SourceProjection::VERSION, document.source_projection_version
          assert_equal "complete", document.source_projection_summary.fetch("state")
          assert_equal [2, 2, 2], projection_counts(document)
          assert import(original, contents).success?
          assert import(relocated, contents).success?
          assert_equal facts, semantic_rows(document.reload)
          assert_equal 3, document.import_logs.count
          assert_equal File.realpath(File.join(relocated, "record.xml")), document.latest_successful_path
          latest = document.import_logs.reorder(:id).last
          assert_equal true, latest.provenance.fetch("unchanged_bytes")
          assert_equal false, latest.provenance.fetch("source_projection_updated")
          assert_equal false, latest.provenance.fetch("projection_version_changed")
        end
      end
    end

    test "missing and old projection markers upgrade identical bytes while preserving F1 facts" do
      [nil, "cnw_sources_v0"].each_with_index do |previous_version, index|
        in_directory do |directory|
          contents = xml(key: "UPGRADE-#{index}")
          assert import(directory, contents).success?
          document = CatalogueDocument.find_by!(record_key: "UPGRADE-#{index}")
          # Synthetic branch setup; the separate acceptance experiment starts
          # with the actual unchanged F1 schema/importer before migration.
          document.source_relations.delete_all
          HeldItem.where(catalogue_document_id: document.id).delete_all
          document.source_descriptions.delete_all
          previous_summary = previous_version ? document.source_projection_summary : nil
          document.update_columns(source_projection_version: previous_version, source_projection_summary: previous_summary)
          before = f1_rows(document.work)
          identity = [document.id, document.work.id, document.committed_sha256]
          assert import(directory, contents).success?
          document.reload
          assert_equal identity, [document.id, document.work.id, document.committed_sha256]
          assert_equal before, f1_rows(document.work)
          assert_equal [2, 2, 2], projection_counts(document)
          latest = document.import_logs.reorder(:id).last
          if previous_version.nil?
            assert_nil latest.provenance.fetch("old_source_projection_version")
          else
            assert_equal previous_version, latest.provenance.fetch("old_source_projection_version")
          end
          assert_equal SourceProjection::VERSION, latest.provenance.fetch("new_source_projection_version")
          assert_equal true, latest.provenance.fetch("unchanged_bytes")
          assert_equal true, latest.provenance.fetch("projection_version_changed")
          facts = semantic_rows(document)
          assert import(directory, contents).success?
          assert_equal facts, semantic_rows(document.reload)
        end
      end
    end

    test "changed projection reorders and removes only its own facts preserving surviving identities" do
      in_directory do |first|
        in_directory do |other|
          initial_sources = source("a", items: '<item xml:id="ia"/><item xml:id="move"/>', target: "#b") +
            source("b", items: '<item xml:id="ib"/>', target: "#a") + source("removed", items: '<item xml:id="ir"/>', target: "#a")
          assert import(first, xml(sources: initial_sources)).success?
          assert import(other, xml(key: "OTHER", sources: initial_sources)).success?
          document = CatalogueDocument.find_by!(record_key: "F2-SYNTHETIC")
          other_document = CatalogueDocument.find_by!(record_key: "OTHER")
          other_facts = semantic_rows(other_document)
          other_logs = other_document.import_logs.reorder(:id).map(&:attributes)
          source_ids = document.source_descriptions.pluck(:xml_id, :id).to_h
          item_ids = document.held_items.pluck(:xml_id, :id).to_h
          replacement = source("b", items: '<item xml:id="move"/><item xml:id="ib"/>', target: "#a") +
            source("a", items: '<item xml:id="ia"/>', target: "#b")
          assert import(first, xml(sources: replacement)).success?
          assert_equal %w[b a], document.source_descriptions.order(:source_order).pluck(:xml_id)
          assert_equal source_ids.slice("a", "b"), document.source_descriptions.pluck(:xml_id, :id).to_h
          assert_equal item_ids.slice("ia", "move", "ib"), document.held_items.pluck(:xml_id, :id).to_h
          assert_equal source_ids.fetch("b"), document.held_items.find_by!(xml_id: "move").source_description_id
          assert_equal [2, 3, 2], projection_counts(document)
          assert_equal other_facts, semantic_rows(other_document.reload)
          assert_equal other_logs, other_document.import_logs.reorder(:id).map(&:attributes)
          assert document.source_relations.all? { |edge| edge.target_source_description.catalogue_document_id == document.id }
        end
      end
    end

    test "incoming source and item growth reserves ordinals beyond all final positions" do
      %w[sources items].each do |kind|
        in_directory do |directory|
          retained = source("retained", items: '<item xml:id="retained-item"/>', rel: "isEmbodimentOf")
          assert import(directory, xml(key: "GROW-#{kind}", sources: retained)).success?
          document = CatalogueDocument.find_by!(record_key: "GROW-#{kind}")
          source_id = document.source_descriptions.sole.id
          item_id = document.held_items.sole.id
          replacement = if kind == "sources"
            3.times.map { |index| source("new-#{index}", items: "", rel: "isEmbodimentOf") }.join + retained
          else
            new_items = 3.times.map { |index| '<item xml:id="new-item-' + index.to_s + '"/>' }.join
            source("retained", items: new_items + '<item xml:id="retained-item"/>', rel: "isEmbodimentOf")
          end
          assert import(directory, xml(key: "GROW-#{kind}", sources: replacement)).success?, kind
          assert_equal source_id, document.source_descriptions.find_by!(xml_id: "retained").id
          assert_equal item_id, document.held_items.find_by!(xml_id: "retained-item").id
          ordered_scope = kind == "sources" ? document.source_descriptions : document.held_items
          assert_equal [1, 2, 3, 4], ordered_scope.reorder(:source_order).pluck(:source_order)
          assert_equal(kind == "sources" ? "retained" : "retained-item", ordered_scope.reorder(:source_order).last.xml_id)
        end
      end
    end

    test "source writes before relation completion roll back with one safe associated failure" do
      failing_importer = Class.new(Importer) do
        private

        def projection_attributes(row, except:)
          raise ActiveRecord::StatementInvalid, "Injected /private/source.xml <payload>" if row.key?("relation_order")

          super
        end
      end
      assert_atomic_failure_and_recovery(failing_importer)
    end

    test "real source constraint failure restores projection hash marker and all timestamps" do
      failing_importer = Class.new(Importer) do
        private

        def replace_source_projection(document, work, projection)
          super
          # Bypass the model after projection writes; the database positive-order
          # constraint must reject this before the version marker can commit.
          document.source_descriptions.first.update_columns(source_order: 0)
        end
      end
      assert_atomic_failure_and_recovery(failing_importer)
    end

    test "same-byte mapping upgrade still checks prior successful path ownership first" do
      in_directory do |path_a|
        in_directory do |path_b|
          a_bytes = xml(key: "A")
          b_bytes = xml(key: "B")
          assert import(path_a, a_bytes).success?
          assert import(path_b, b_bytes).success?
          a = CatalogueDocument.find_by!(record_key: "A")
          b = CatalogueDocument.find_by!(record_key: "B")
          b.update_columns(source_projection_version: "cnw_sources_v0")
          before = domain_rows
          b_log_count = b.import_logs.count
          result = import(path_a, b_bytes)
          assert_equal [1, 0, 1], [result.files_seen, result.successes, result.failures]
          assert_equal before, domain_rows
          failure = ImportLog.order(:id).last
          assert_equal a.id, failure.catalogue_document_id
          assert_equal "B", failure.attempted_record_key
          assert_equal b_log_count, b.import_logs.count
          assert_equal "cnw_sources_v0", b.reload.source_projection_version
        end
      end
    end

    test "otherwise eligible inputs import inert declaration literals in comments and title CDATA" do
      ["<!DOCTYPE mei>", '<!ENTITY example "inert">'].each_with_index do |literal, literal_index|
        %w[comment cdata].each do |placement|
          in_directory do |directory|
            key = "INERT-#{literal_index}-#{placement}"
            contents = xml(key: key)
            contents = if placement == "comment"
              contents.sub("<meiHead>", "<!-- #{literal} --><meiHead>")
            else
              contents.sub("Work title", "<![CDATA[#{literal}]]>")
            end
            result = import(directory, contents)
            assert_equal [1, 1, 0], [result.files_seen, result.successes, result.failures]
            document = CatalogueDocument.find_by!(record_key: key)
            assert_equal(placement == "comment" ? "Work title" : literal, document.work.title)
            assert_equal [2, 2, 2], projection_counts(document)
            assert_equal "success", document.import_logs.sole.status
          end
        end
      end
    end

    private

    def assert_atomic_failure_and_recovery(importer_class)
      in_directory do |directory|
        original = xml
        assert import(directory, original).success?
        document = CatalogueDocument.sole
        original_success = document.import_logs.reorder(:id).last
        before = domain_rows
        previous_log_count = ImportLog.count
        replacement = original.sub("Work title", "Attempted title").sub("Source a", "Attempted source")
        result = import(directory, replacement, importer_class: importer_class)
        assert_equal [1, 0, 1], [result.files_seen, result.successes, result.failures]
        assert_equal before, domain_rows
        assert_equal previous_log_count + 1, ImportLog.count
        failure = document.import_logs.reorder(:id).last
        assert_equal "failure", failure.status
        assert_equal document.work.id, failure.work_id
        assert_equal Digest::SHA256.hexdigest(original), failure.previous_committed_sha256
        assert_equal Digest::SHA256.hexdigest(replacement), failure.attempted_sha256
        assert_equal SourceProjection::VERSION, failure.provenance.fetch("previous_source_projection_version")
        assert_equal SourceProjection::VERSION, failure.provenance.fetch("attempted_source_projection_version")
        assert_equal "Database constraint rejected the imported record", failure.error_message
        assert_equal original_success.id, document.work.last_successful_import.id
        assert_failure_visible_with_retained_projection(document, failure, original_success, original)
        assert import(directory, replacement).success?
        assert_equal "success", document.work.reload.latest_import_attempt.status
        assert_equal "Attempted title", document.work.title
        assert_equal 1, document.import_logs.where(status: "failure").count
      end
    end

    def assert_failure_visible_with_retained_projection(document, failure, original_success, original)
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.get "/api/works/#{document.work.id}.json"
      assert_equal 200, session.response.status
      data = JSON.parse(session.response.body)
      assert_equal "Work title", data.fetch("title")
      assert_equal failure.id, data.fetch("latest_import_attempt").fetch("id")
      assert_equal "failure", data.fetch("latest_import_attempt").fetch("status")
      assert_equal "Database constraint rejected the imported record", data.fetch("latest_import_attempt").fetch("error_message")
      assert_equal original_success.id, data.fetch("last_successful_import").fetch("id")
      sources = data.fetch("catalogue_sources")
      assert_equal Digest::SHA256.hexdigest(original), sources.fetch("document").fetch("committed_sha256")
      assert_equal SourceProjection::VERSION, sources.fetch("projection").fetch("version")
      assert_equal %w[a b], sources.fetch("descriptions").map { |source| source.fetch("xml_id") }
      assert_equal ["Source a", "Source b"], sources.fetch("descriptions").map { |source| source.fetch("titles").first.fetch("text") }
      assert_not_includes session.response.body, "Injected /private/source.xml"
      assert_not_includes session.response.body, "<payload>"
      assert_not_includes session.response.body, "Attempted source"

      session.get "/works/#{document.work.id}"
      assert_equal 200, session.response.status
      html = Nokogiri::HTML(session.response.body)
      assert_match(/Status: failure/, html.at_css("#latest-import-attempt").text)
      assert_equal "Error: Database constraint rejected the imported record", html.at_css("#latest-import-attempt .import-error").text.strip
      assert_includes html.at_css("#last-successful-import").text, Digest::SHA256.hexdigest(original)
      assert_equal "Work title", html.at_css("h1").text.strip
      assert_equal "Source a", html.at_css("[data-source-xml-id='a'] [data-field='titles'] .source-value").text.strip
      assert_not_includes session.response.body, "Injected /private/source.xml"
      assert_not_includes session.response.body, "&lt;payload&gt;"
      assert_not_includes session.response.body, "Attempted source"
    end

    def source(id, items: '<item xml:id="item-a"/>', target: "#expression-one", rel: "isReproductionOf")
      <<~XML
        <manifestation xml:id="#{id}"><titleStmt><title>Source #{id}</title></titleStmt><itemList>#{items}</itemList>
          <relationList><relation rel="#{rel}" target="#{target}"/></relationList>
        </manifestation>
      XML
    end

    def xml(key: "F2-SYNTHETIC", sources: nil)
      sources ||= source("a", rel: "isEmbodimentOf") + source("b", items: '<item xml:id="item-b"/>', target: "#a")
      <<~XML
        <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1" xml:id="synthetic-document">
          <meiHead><workList><work xml:id="synthetic-work"><identifier label="CNW">#{key}</identifier><title>Work title</title>
            <composer><persName>Synthetic composer</persName></composer><classification><term>Music</term></classification>
            <movement n="1"><title>Movement</title></movement><expressionList><expression xml:id="expression-one"><title>Expression</title></expression></expressionList>
          </work></workList><manifestationList>#{sources}</manifestationList></meiHead>
        </mei>
      XML
    end

    def in_directory
      directory = Dir.mktmpdir("f2-importer-", Rails.root.join("tmp"))
      yield directory
    end

    def import(directory, contents, importer_class: Importer)
      File.write(File.join(directory, "record.xml"), contents)
      importer_class.new(directory: directory).call
    end

    def projection_counts(document)
      [document.source_descriptions.count, document.held_items.count, document.source_relations.count]
    end

    def f1_rows(work)
      { "work" => work.reload.attributes, "children" => %i[work_titles work_classification_terms catalogue_identifiers movements
        instrumentations source_references performances external_references].to_h do |association|
        [association, work.public_send(association).reorder(:id).map(&:attributes)]
      end }
    end

    def semantic_rows(document)
      f1_rows(document.work).merge("sources" => document.source_descriptions.reorder(:id).map(&:attributes),
        "items" => document.held_items.reorder(:id).map(&:attributes), "relations" => document.source_relations.reorder(:id).map(&:attributes))
    end

    def domain_rows
      [CatalogueDocument, Work, Composer, WorkTitle, WorkClassificationTerm, CatalogueIdentifier, Movement, Instrumentation,
        SourceReference, Performance, ExternalReference, SourceDescription, HeldItem, SourceRelation].to_h do |model|
        [model.name, model.order(:id).map(&:attributes)]
      end
    end
  end
end
