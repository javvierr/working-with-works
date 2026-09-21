# Pure XML projection tests; also runnable without Rails or a database.
require "minitest/autorun"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "json"
require "tmpdir"
require_relative "../../../app/services/mei/input_document"
require_relative "../../../app/services/mei/source_projection"

module Mei
  class SourceProjectionTest < Minitest::Test
    def test_source_absence_does_not_promote_documentary_metadata
      result = project(work_extra: '<bibl><genre>manuscript</genre><repository>Not a held item</repository><manifestation xml:id="nested"/></bibl>')
      assert_empty result.fetch("descriptions")
      assert_equal "absent_in_source", result.dig("summary", "state")
      assert_equal 0, result.dig("summary", "source_nodes")
      assert_equal 0, result.dig("summary", "item_nodes")
    end

    def test_selected_values_preserve_blanks_duplicates_metadata_and_document_order
      sources = <<~XML
        <manifestation xml:id="source-a" label="  Label  ">
          <titleStmt xml:id="titles"><title xml:lang="da" type="source">  Score\t draft </title><title> </title></titleStmt>
          <classification auth="scheme"><termList xml:id="terms"><term>score</term><term>score</term><term class="#blank"> </term>
            <termList><term>nested owned term</term></termList><bibl><term>foreign term</term></bibl><classification><term>foreign classification</term></classification>
          </termList></classification>
          <pubStmt><date>1920</date><publisher>Publisher</publisher><pubPlace>Place</pubPlace></pubStmt>
          <physDesc><plateNum>Plate</plateNum><titlePage>Complete scope wording</titlePage></physDesc>
        </manifestation>
      XML
      source = project(sources: sources).fetch("descriptions").sole
      assert_equal "Label", source.fetch("label")
      assert_equal "  Label  ", source.fetch("attributes").fetch("label")
      assert_equal ["Score draft", nil], source.fetch("titles").map { |row| row.fetch("text") }
      assert_equal "  Score\t draft ", source.fetch("titles").first.fetch("raw_text")
      assert_equal "titles", source.fetch("titles").first.dig("title_stmt_metadata", "xml_id")
      assert_equal ["score", "score", nil, "nested owned term"], source.fetch("classification_terms").map { |row| row.fetch("text") }
      assert_equal [1, 2, 3, 4], source.fetch("classification_terms").map { |row| row.fetch("source_order") }
      assert_equal ["date", "publisher", "pubPlace"], source.fetch("publication").map { |row| row.fetch("element") }
      assert_equal ["plateNum", "titlePage"], source.fetch("physical_description").map { |row| row.fetch("element") }
      assert_equal "descriptive", source.fetch("state")
    end

    def test_foreign_term_list_wrapper_is_not_reported_as_mei_term_list_metadata
      sources = <<~XML
        <manifestation xml:id="source-a"><classification><termList xml:id="mei-list">
          <x:termList xmlns:x="urn:foreign" xml:id="foreign-list"><term>Owned MEI term</term></x:termList>
        </termList></classification></manifestation>
      XML
      terms = project(sources: sources).fetch("descriptions").sole.fetch("classification_terms")
      assert_equal ["Owned MEI term"], terms.map { |row| row.fetch("text") }
      assert_equal ["mei-list"], terms.sole.fetch("term_list_metadata").map { |metadata| metadata.fetch("xml_id") }
    end

    def test_source_and_item_states_depend_on_their_own_selected_payload
      sources = <<~XML
        <manifestation xml:id="labelled" label="Only label"><itemList><item xml:id="empty"/></itemList></manifestation>
        <manifestation xml:id="linked"><ptr target="https://example.invalid/inert"/></manifestation>
        <manifestation xml:id="empty-source"><itemList><item xml:id="descriptive-item"><identifier>Item value</identifier></item></itemList></manifestation>
      XML
      rows = project(sources: sources).fetch("descriptions")
      assert_equal %w[label_or_link_stub label_or_link_stub empty_placeholder], rows.map { |row| row.fetch("state") }
      assert_equal "empty_placeholder", rows[0].fetch("held_items").sole.fetch("state")
      assert_equal "descriptive", rows[2].fetch("held_items").sole.fetch("state")
      assert_equal "missing", rows[0].fetch("held_items").sole.dig("availability", "repositories")
      assert_equal "https://example.invalid/inert", rows[1].fetch("links").sole.dig("attributes", "target")
    end

    def test_repository_and_location_identifiers_remain_separate_and_ordered
      sources = <<~XML
        <manifestation xml:id="source-a"><itemList><item xml:id="item-a">
          <identifier>A</identifier><identifier>A</identifier>
          <physLoc xml:id="location-a"><repository auth="RISM" auth.uri="https://authority.invalid/">
            <identifier>DK-Kk</identifier><identifier>Other repository ID</identifier><corpName>Library</corpName><corpName>Second name</corpName>
            <ptr target="https://repository.invalid/inert"/>
          </repository><identifier>CNS 332c</identifier><identifier>Acc. 2001/21</identifier>
          <repository><corpName>Another repository</corpName></repository></physLoc>
          <physLoc><identifier>Another location</identifier></physLoc>
          <bibl><repository><identifier>Not owned</identifier></repository></bibl>
        </item></itemList></manifestation>
      XML
      item = project(sources: sources).fetch("descriptions").sole.fetch("held_items").sole
      assert_equal ["A", "A"], item.fetch("identifiers").map { |row| row.fetch("text") }
      locations = item.fetch("physical_locations")
      assert_equal 2, locations.length
      assert_equal ["CNS 332c", "Acc. 2001/21"], locations.first.fetch("identifiers").map { |row| row.fetch("text") }
      repositories = locations.first.fetch("repositories")
      assert_equal 2, repositories.length
      assert_equal ["DK-Kk", "Other repository ID"], repositories.first.fetch("identifiers").map { |row| row.fetch("text") }
      assert_equal ["Library", "Second name"], repositories.first.fetch("names").map { |row| row.fetch("text") }
      assert_equal "RISM", repositories.first.dig("attributes", "auth")
      assert_equal "present", item.dig("availability", "repositories")
      refute_includes item.to_json, "Not owned"
    end

    def test_nested_expression_context_and_reused_document_local_ids
      sources = '<manifestation xml:id="source-a"><relationList><relation rel="isEmbodimentOf" target="#nested"/></relationList></manifestation>'
      expressions = '<expression xml:id="parent"><title>Parent title</title><expressionList><expression xml:id="nested"><title>Nested title</title></expression></expressionList></expression>'
      relation = project(sources: sources, expressions: expressions).fetch("descriptions").sole.fetch("relations").sole
      assert_equal "resolved_expression", relation.fetch("resolution_state")
      assert_equal "nested", relation.dig("expression_context", "xml_id")
      assert_equal ["parent"], relation.dig("expression_context", "ancestor_expressions").map { |row| row.fetch("xml_id") }
      assert_equal "synthetic-work", relation.dig("expression_context", "containing_work", "xml_id")
      other = project(sources: sources, expressions: '<expression xml:id="nested"><title>Different document</title></expression>')
      assert_equal "Different document", other.fetch("descriptions").sole.fetch("relations").sole.dig("expression_context", "titles", 0, "text")
      foreign = project(sources: sources, expressions: '<x:expression xmlns:x="urn:foreign" xml:id="nested"><title>Not an MEI expression</title></x:expression>')
        .fetch("descriptions").sole.fetch("relations").sole
      assert_equal "#nested", foreign.fetch("target_token")
      assert_equal "unresolved", foreign.fetch("resolution_state")
      assert_equal "wrong_target_type", foreign.fetch("resolution_reason")
      assert_nil foreign.fetch("expression_context")
      assert_nil foreign.fetch("target_source_xml_id")
    end

    def test_reproduction_self_and_cycles_are_direct_statements_without_inferred_edges
      sources = <<~XML
        <manifestation xml:id="a"><relationList><relation rel="isReproductionOf" target="#b #a"/></relationList></manifestation>
        <manifestation xml:id="b"><relationList><relation rel="hasReproduction" target="#a"/></relationList></manifestation>
      XML
      result = project(sources: sources)
      relations = result.fetch("descriptions").flat_map { |source| source.fetch("relations") }
      assert_equal 3, relations.length
      assert_equal ["b", "a", "a"], relations.map { |row| row.fetch("target_source_xml_id") }
      assert_equal %w[resolved_source resolved_source resolved_source], relations.map { |row| row.fetch("resolution_state") }
      assert relations.all? { |row| row.fetch("expression_context").nil? }
      assert_equal [1, 2, 1], relations.map { |row| row.fetch("token_order") }
    end

    def test_relation_tokens_preserve_mixed_outcomes_and_precedence
      sources = <<~XML
        <manifestation xml:id="a"><relationList>
          <relation xml:id="mixed" rel="isEmbodimentOf" target=" #expression-one\t#missing other.xml#expression-one https://example.invalid/x #a #outside #expression-one?x #expression-one#extra "/>
          <relation rel="unknown"/><relation rel="unknown" target="#expression-one"/>
          <relation rel="isReproductionOf" target="#unsupported-source"/>
        </relationList></manifestation>
      XML
      result = project(sources: sources, extra: '<expression xml:id="outside"/><manifestation xml:id="unsupported-source"/>')
      relations = result.fetch("descriptions").sole.fetch("relations")
      assert_equal ["resolved_expression"] + ["unresolved"] * 10, relations.map { |row| row.fetch("resolution_state") }
      assert_equal [nil, "missing_fragment", "unsupported_target_form", "unsupported_target_form", "wrong_target_type", "expression_outside_supported_work", "unsupported_target_form", "unsupported_target_form", "missing_target", "unsupported_relation_type", "unsupported_source_target"], relations.map { |row| row.fetch("resolution_reason") }
      assert_equal ["mixed"] * 8, relations.first(8).map { |row| row.fetch("xml_id") }
      assert_equal "partial", result.dig("summary", "state")
      assert_equal 10, result.dig("summary", "unresolved_relations")
    end

    def test_missing_id_omissions_and_issue_bounds_are_explicit
      missing_items = '<item/>' * 55
      sources = '<manifestation><itemList><item xml:id="omitted-child"/></itemList><relationList><relation rel="isEmbodimentOf" target="#expression-one"/></relationList></manifestation>' +
        '<manifestation xml:id="represented"><itemList>' + missing_items + '<item xml:id="last"/></itemList></manifestation>'
      result = project(sources: sources)
      summary = result.fetch("summary")
      assert_equal "partial", summary.fetch("state")
      assert_equal [2, 1, 1], summary.values_at("source_nodes", "represented_sources", "unsupported_sources")
      assert_equal [57, 1, 56], summary.values_at("item_nodes", "represented_items", "unsupported_items")
      assert_equal 1, summary.fetch("unsupported_relation_nodes")
      assert_equal 50, summary.fetch("issues").length
      assert summary.fetch("issues_truncated")
      assert_operator summary.fetch("issue_count"), :>, 50
      source = result.fetch("descriptions").sole
      assert_equal 2, source.fetch("source_order")
      assert_equal 56, source.fetch("held_items").sole.fetch("source_order")
    end

    private

    def project(sources: "", expressions: '<expression xml:id="expression-one"><title>Expression</title></expression>', work_extra: "", extra: "")
      directory = Dir.mktmpdir("f2-pure-projection-")
      path = File.join(directory, "synthetic.xml")
      File.write(path, <<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1">
          <meiHead><workList><work xml:id="synthetic-work"><identifier label="CNW">SYNTHETIC-F2</identifier><title>Work</title>
            <expressionList>#{expressions}</expressionList>#{work_extra}
          </work></workList><manifestationList>#{sources}</manifestationList>#{extra}</meiHead>
        </mei>
      XML
      input = InputDocument.new(path: path, directory: directory, input_profile: "official_cnw_v401").read
      assert input.valid?, input.error&.message
      SourceProjection.new(input).call
    end
  end
end
