require "test_helper"
require "tmpdir"

# Synthetic source records exercise the persisted interface contract. Real XML
# fidelity and browser checks have separate independent F2 evidence.
class CatalogueSourcesIntegrationTest < ActionDispatch::IntegrationTest
  test "legacy and unprojected data never claim source absence" do
    legacy = works(:one)
    get api_work_url(legacy, format: :json)
    data = JSON.parse(response.body).fetch("catalogue_sources")
    assert_nil data.fetch("document")
    assert_equal({ "version" => nil, "summary" => { "state" => "not_projected" } }, data.fetch("projection"))
    assert_empty data.fetch("descriptions")
    get work_url(legacy)
    assert_select "#catalogue-sources[data-projection-state='not_projected']", text: /presence or absence is unknown/

    work = import_work("")
    work.catalogue_document.update!(source_projection_version: nil, source_projection_summary: nil)
    get api_work_url(work, format: :json)
    data = JSON.parse(response.body).fetch("catalogue_sources")
    assert_equal "F2-UI", data.fetch("document").fetch("record_key")
    assert_equal({ "state" => "not_projected" }, data.fetch("projection").fetch("summary"))
  end

  test "true source absence differs from a description without relationships or items" do
    absent = import_work("", key: "F2-absent")
    get api_work_url(absent, format: :json)
    assert_equal "absent_in_source", JSON.parse(response.body).dig("catalogue_sources", "projection", "summary", "state")
    get work_url(absent)
    assert_select "#catalogue-sources", text: /No source-description nodes are supplied/
    assert_select "#catalogue-sources [data-source-xml-id]", count: 0

    work = import_work('<manifestation xml:id="standalone"><titleStmt><title>Score, print</title></titleStmt></manifestation>')
    get work_url(work)
    assert_select "[data-source-xml-id='standalone']", text: /Relationship unspecified/
    assert_select "[data-source-xml-id='standalone']", text: /No held-item nodes are supplied/
    assert_select "#catalogue-sources[data-projection-state='complete']"
  end

  test "item parent grouping repositories and every location identifier survive both interfaces" do
    work = import_work(<<~XML)
      <manifestation xml:id="score"><titleStmt><title xml:lang="da" type="main">Score draft</title></titleStmt>
        <itemList><item xml:id="copy"><physLoc>
          <repository auth="agency"><identifier>DK-A</identifier><identifier type="alternate">ALT</identifier><corpName>Archive A</corpName></repository>
          <repository><identifier>DK-B</identifier><corpName>Archive B</corpName></repository>
          <identifier>Loc 1</identifier><identifier>Loc 2</identifier>
        </physLoc></item></itemList>
        <relationList><relation rel="isEmbodimentOf" target="#expression_inner"/></relationList>
      </manifestation>
      <manifestation xml:id="text"><titleStmt><title>Printed text</title></titleStmt><itemList><item xml:id="empty"/></itemList></manifestation>
    XML
    get api_work_url(work, format: :json)
    assert_response :success
    sources = JSON.parse(response.body).fetch("catalogue_sources").fetch("descriptions")
    assert_equal %w[score text], sources.map { |source| source.fetch("xml_id") }
    assert_equal [%w[copy], %w[empty]], sources.map { |source| source.fetch("held_items").map { |item| item.fetch("xml_id") } }
    item = sources.first.fetch("held_items").first
    assert_equal "score", item.fetch("source_xml_id")
    location = item.fetch("physical_locations").first
    assert_equal [%w[DK-A ALT], %w[DK-B]], location.fetch("repositories").map { |repo| repo.fetch("identifiers").map { |value| value.fetch("text") } }
    assert_equal ["Loc 1", "Loc 2"], location.fetch("identifiers").map { |value| value.fetch("text") }
    relation = sources.first.fetch("relations").first
    assert_equal "expression_inner", relation.fetch("expression_context").fetch("xml_id")
    assert_equal ["expression_outer"], relation.fetch("expression_context").fetch("ancestor_expressions").map { |ancestor| ancestor.fetch("xml_id") }
    assert_equal "empty_placeholder", sources.last.fetch("held_items").first.fetch("state")
    assert_not_includes JSON.generate(sources), @input_directory

    get work_url(work)
    assert_select "[data-source-xml-id='score'] [data-item-xml-id='copy']", count: 1
    assert_select "[data-source-xml-id='text'] [data-item-xml-id='empty']", count: 1
    assert_select "[data-source-xml-id='text'] [data-item-xml-id='copy']", count: 0
    assert_select "[data-item-xml-id='copy'] [data-field='location-identifiers'] .source-value", text: "Loc 1"
    assert_select "[data-item-xml-id='copy'] [data-field='location-identifiers'] .source-value", text: "Loc 2"
    assert_select "[data-item-xml-id='copy'] [data-repository-order]", count: 2
    assert_select "[data-item-xml-id='empty'] .item-state", text: /does not establish a held copy or location/
    assert_select "[data-source-xml-id='score'] .expression-context", text: /expression_inner/
    assert_select "#catalogue-sources", text: /Ancestor expression context/
    assert_select "#legacy-source-references h2", text: "Legacy source references"
    assert_select "#catalogue-sources", text: /Location identifier/
  end

  test "source navigation is local while malicious text and pointer targets stay inert" do
    work = import_work(<<~XML)
      <manifestation xml:id="a" label="&lt;img src=x onerror=bad&gt;">
        <titleStmt><title><![CDATA[<script>bad()</script>]]></title></titleStmt>
        <ptr target="javascript:bad()"/><notesStmt><annot><![CDATA[<!DOCTYPE inert>]]></annot></notesStmt>
        <relationList><relation rel="isReproductionOf" target="#b"/><relation rel="isEmbodimentOf" target="https://invalid.example/#x"/></relationList>
      </manifestation>
      <manifestation xml:id="b" label="Other source"><relationList><relation rel="hasReproduction" target="#a"/></relationList></manifestation>
    XML
    get api_work_url(work, format: :json)
    sources = JSON.parse(response.body).dig("catalogue_sources", "descriptions")
    assert_equal "b", sources.first.fetch("relations").first.fetch("target_source_xml_id")
    assert_equal "unsupported_target_form", sources.first.fetch("relations").last.fetch("resolution_reason")
    get work_url(work)
    assert_select "#catalogue-sources script, #catalogue-sources img", count: 0
    assert_select "#catalogue-sources a[href^='javascript:'], #catalogue-sources a[href^='http']", count: 0
    assert_select "#catalogue-sources a[href^='#catalogue-source-']", count: 2
    assert_select "[data-source-xml-id='a'] [data-resolution-state='unresolved']", text: /unsupported target form/
    assert_select "[data-source-xml-id='a'] .source-relationship", text: /Relationship unspecified/
    assert_includes response.body, "&lt;script&gt;bad()&lt;/script&gt;"
  end

  test "unsupported nodes are partial with honest counts rather than absent" do
    work = import_work(<<~XML)
      <manifestation><itemList><item xml:id="omitted_item"/></itemList></manifestation>
      <manifestation xml:id="stub" label="Source link"><ptr target="relative.xml"/><itemList><item/></itemList></manifestation>
    XML
    get api_work_url(work, format: :json)
    data = JSON.parse(response.body).fetch("catalogue_sources")
    summary = data.fetch("projection").fetch("summary")
    assert_equal "partial", summary.fetch("state")
    assert_equal 2, summary.fetch("source_nodes")
    assert_equal 1, summary.fetch("represented_sources")
    assert_equal 2, summary.fetch("unsupported_items")
    assert_equal "label_or_link_stub", data.fetch("descriptions").first.fetch("state")
    get work_url(work)
    assert_select "#catalogue-sources[data-projection-state='partial']", text: /representation is partial/
    assert_select "[data-source-xml-id]", count: 1
    assert_select "[data-item-xml-id]", count: 0
    assert_select "#catalogue-sources", text: /Unsupported or unresolved details/
  end

  test "detail GET uses persisted facts without opening or parsing source XML" do
    work = import_work('<manifestation xml:id="persisted"><titleStmt><title>Persisted score</title></titleStmt></manifestation>')
    original = Mei::InputDocument.method(:new)
    Mei::InputDocument.define_singleton_method(:new) { |*| raise "GET must not parse XML" }
    get api_work_url(work, format: :json)
    assert_response :success
    assert_equal "Persisted score", JSON.parse(response.body).dig("catalogue_sources", "descriptions", 0, "titles", 0, "text")
    get work_url(work)
    assert_response :success
    assert_select "[data-source-xml-id='persisted'] [data-field='titles'] .source-value", text: "Persisted score"
  ensure
    Mei::InputDocument.define_singleton_method(:new, original) if original
  end

  private

  def import_work(sources, key: "F2-UI")
    @input_directory = Dir.mktmpdir("f2-source-interface-")
    File.write(File.join(@input_directory, "record.xml"), <<~XML)
      <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1" xml:id="document">
        <meiHead><workList><work xml:id="work"><identifier label="CNW">#{key}</identifier><title>Interface work</title>
          <expressionList><expression xml:id="expression_outer"><title>Outer expression</title><expressionList><expression xml:id="expression_inner"><title>Inner expression</title></expression></expressionList></expression></expressionList>
        </work></workList><manifestationList>#{sources}</manifestationList></meiHead>
      </mei>
    XML
    result = Mei::Importer.new(directory: @input_directory).call
    assert_equal 1, result.successes, result.inspect
    CatalogueDocument.find_by!(input_profile: "official_cnw_v401", catalogue: "CNW", record_key: key).work
  end
end
