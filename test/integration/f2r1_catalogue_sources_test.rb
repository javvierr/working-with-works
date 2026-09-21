require "test_helper"
require "tmpdir"

# These F2-R1 inputs and each imported copy are intentionally retained. Existing
# inherited tests have their own fixture lifecycles; this class changes none.
class F2R1CatalogueSourcesIntegrationTest < ActionDispatch::IntegrationTest
  ABSENCE_SENTENCE = "No held-item nodes are supplied for this description."
  REPRESENTED_EMPTY = "No held-item descriptions are represented here."

  SYNTHETIC_SOURCES = {
    "c2_missing_id_only" => <<~XML,
      <manifestation xml:id="stub" label="Source link"><ptr target="relative.xml"/><itemList><item/></itemList></manifestation>
    XML
    "c3_mixed_items" => <<~XML,
      <manifestation xml:id="mixed"><titleStmt><title>Mixed items</title></titleStmt><itemList><item xml:id="represented"/><item/></itemList></manifestation>
    XML
    "c4_zero_items" => <<~XML,
      <manifestation xml:id="standalone"><titleStmt><title>Source without held items</title></titleStmt></manifestation>
    XML
    "c4_absent_sources" => "",
    "c5_other_owner" => <<~XML,
      <manifestation xml:id="empty"><titleStmt><title>Empty source</title></titleStmt></manifestation>
      <manifestation xml:id="omitted"><titleStmt><title>Source containing the omitted item</title></titleStmt><itemList><item/></itemList></manifestation>
    XML
    "c6_truncated_issues" => ("<manifestation/>\n" * 51) + <<~XML,
      <manifestation xml:id="after_limit"><itemList><item/></itemList></manifestation>
    XML
    "c7_safe_states" => <<~XML
      <manifestation xml:id="stub" label="&lt;script&gt;source_bad()&lt;/script&gt;">
        <ptr target="javascript:source_bad()"/>
        <itemList>
          <item xml:id="first" label="&lt;img src=x onerror=bad()&gt;"><ptr target="javascript:item_bad()"/></item>
          <item xml:id="second"/>
          <item xml:id="third"><physLoc/></item>
        </itemList>
      </manifestation>
      <manifestation xml:id="placeholder"/>
    XML
  }.freeze

  test "c2 missing_id_only does not turn unsupported supplied items into absence" do
    work = import_work("c2_missing_id_only")
    data = source_api(work)
    assert_item_counts data, actual: 1, represented: 0, unsupported: 1, state: "partial"
    assert_equal ["stub"], data.fetch("descriptions").map { |source| source.fetch("xml_id") }
    assert_empty data.fetch("descriptions").first.fetch("held_items")

    get work_url(work)
    assert_response :success
    source = source_dom("stub")
    # Keep this assertion before the caption assertion: the retained red run
    # proves the original false supplied-node absence claim directly.
    refute_includes empty_item_message(source), ABSENCE_SENTENCE
    assert_represented_caption source, 0
    assert_record_wide_unsupported_message source
    assert_empty source.css("[data-item-xml-id]")
    assert_select "#catalogue-sources[data-projection-state='partial']", text: /0 represented item nodes from 1/
  end

  test "c3 mixed items count only the correctly parented represented item" do
    work = import_work("c3_mixed_items")
    data = source_api(work)
    assert_item_counts data, actual: 2, represented: 1, unsupported: 1, state: "partial"
    source = data.fetch("descriptions").sole
    assert_equal "mixed", source.fetch("xml_id")
    assert_equal [["represented", "mixed", 1]], source.fetch("held_items").map { |item| item.values_at("xml_id", "source_xml_id", "source_order") }

    get work_url(work)
    assert_response :success
    source = source_dom("mixed")
    assert_represented_caption source, 1
    assert_equal ["represented"], source.css("[data-item-xml-id]").map { |item| item["data-item-xml-id"] }
    refute_includes source.text, ABSENCE_SENTENCE
    assert_select "#catalogue-sources[data-projection-state='partial']", text: /1 represented item nodes from 2/
  end

  test "c4 explicit zero unsupported items permits genuine item and source absence" do
    work = import_work("c4_zero_items")
    data = source_api(work)
    assert_item_counts data, actual: 0, represented: 0, unsupported: 0, state: "complete"
    assert_equal ["standalone"], data.fetch("descriptions").map { |source| source.fetch("xml_id") }
    assert_empty data.fetch("descriptions").sole.fetch("held_items")
    assert_empty data.fetch("descriptions").sole.fetch("relations")
    get work_url(work)
    source = source_dom("standalone")
    assert_represented_caption source, 0
    assert_equal ABSENCE_SENTENCE, empty_item_message(source)
    assert_match(/Relationship unspecified/, source.at_css(".source-relationship").text)

    absent = import_work("c4_absent_sources")
    data = source_api(absent)
    assert_item_counts data, actual: 0, represented: 0, unsupported: 0, state: "absent_in_source"
    assert_empty data.fetch("descriptions")
    get work_url(absent)
    assert_select "#catalogue-sources", text: /No source-description nodes are supplied/
    assert_select "#catalogue-sources [data-source-xml-id]", count: 0
  end

  test "c5 unsupported items elsewhere remain a record wide disclosure" do
    work = import_work("c5_other_owner")
    data = source_api(work)
    assert_item_counts data, actual: 1, represented: 0, unsupported: 1, state: "partial"
    assert_equal %w[empty omitted], data.fetch("descriptions").map { |source| source.fetch("xml_id") }
    assert_equal [[], []], data.fetch("descriptions").map { |source| source.fetch("held_items") }

    get work_url(work)
    assert_response :success
    messages = %w[empty omitted].map do |id|
      source = source_dom(id)
      assert_represented_caption source, 0
      assert_record_wide_unsupported_message source
      assert_empty source.css("[data-item-xml-id]")
      empty_item_message(source)
    end
    # The persisted summary cannot establish a different local absence claim
    # for these two containers, although only one supplied the omitted node.
    assert_equal messages.first, messages.last
  end

  test "c6 an omitted item after fifty retained issues does not become absent" do
    work = import_work("c6_truncated_issues")
    data = source_api(work)
    assert_item_counts data, actual: 1, represented: 0, unsupported: 1, state: "partial"
    summary = data.fetch("projection").fetch("summary")
    assert_equal 52, summary.fetch("source_nodes")
    assert_equal 51, summary.fetch("unsupported_sources")
    assert_equal 1, summary.fetch("represented_sources")
    assert_equal 52, summary.fetch("issue_count")
    assert_equal true, summary.fetch("issues_truncated")
    assert_equal 50, summary.fetch("issues").length
    assert summary.fetch("issues").all? { |issue| issue.fetch("kind") == "source" }, "The omitted item's issue must be beyond the retained list"
    assert_equal [["after_limit", 52, []]], data.fetch("descriptions").map { |source| source.values_at("xml_id", "source_order", "held_items") }

    get work_url(work)
    assert_response :success
    source = source_dom("after_limit")
    assert_represented_caption source, 0
    assert_record_wide_unsupported_message source
    assert_select "#catalogue-sources", text: /Only the first 50 issues are listed; the total count includes all issues/
  end

  test "c7 missing or null unsupported item counts do not imply zero" do
    work = import_work("c4_zero_items", key: "F2R1-c7-unknown")
    document = work.catalogue_document
    original_summary = document.source_projection_summary.deep_dup
    %i[missing null].each do |unknown|
      summary = original_summary.deep_dup
      unknown == :missing ? summary.delete("unsupported_items") : summary["unsupported_items"] = nil
      document.update!(source_projection_summary: summary)
      data = source_api(work)
      observed = data.fetch("projection").fetch("summary")
      unknown == :missing ? refute(observed.key?("unsupported_items")) : assert_nil(observed.fetch("unsupported_items"))
      assert_empty data.fetch("descriptions").sole.fetch("held_items")
      get work_url(work)
      assert_response :success
      source = source_dom("standalone")
      assert_represented_caption source, 0
      message = empty_item_message(source)
      assert_includes message, REPRESENTED_EMPTY
      assert_match(/unknown|cannot be determined/, message)
      refute_includes message, ABSENCE_SENTENCE
      refute_includes message, "This catalogue record contains unsupported item nodes"
    end
  end

  test "c7 legacy and unprojected records keep availability unknown" do
    work = works(:one)
    data = source_api(work)
    assert_nil data.fetch("document")
    assert_equal({ "version" => nil, "summary" => { "state" => "not_projected" } }, data.fetch("projection"))
    assert_empty data.fetch("descriptions")
    get work_url(work)
    assert_select "#catalogue-sources[data-projection-state='not_projected']", text: /presence or absence is unknown/
    refute_includes response.body, ABSENCE_SENTENCE

    work = import_work("c4_zero_items", key: "F2R1-c7-unprojected")
    work.catalogue_document.update!(source_projection_version: nil, source_projection_summary: nil)
    data = source_api(work)
    assert_equal({ "state" => "not_projected" }, data.fetch("projection").fetch("summary"))
    assert_empty data.fetch("descriptions")
    get work_url(work)
    assert_select "#catalogue-sources[data-projection-state='not_projected']", text: /presence or absence is unknown/
    assert_select "#catalogue-sources [data-source-xml-id]", count: 0
    refute_includes response.body, ABSENCE_SENTENCE
  end

  test "c7 ordered items placeholders missing locations and inert text remain intact" do
    work = import_work("c7_safe_states")
    data = source_api(work)
    assert_item_counts data, actual: 3, represented: 3, unsupported: 0, state: "complete"
    sources = data.fetch("descriptions")
    assert_equal [["stub", "label_or_link_stub"], ["placeholder", "empty_placeholder"]], sources.map { |source| source.values_at("xml_id", "state") }
    items = sources.first.fetch("held_items")
    assert_equal [["first", "stub", 1], ["second", "stub", 2], ["third", "stub", 3]], items.map { |item| item.values_at("xml_id", "source_xml_id", "source_order") }
    assert_equal ["label_or_link_stub", "empty_placeholder", "empty_placeholder"], items.map { |item| item.fetch("state") }
    assert_empty items[1].fetch("physical_locations")
    assert_empty items[2].fetch("physical_locations").sole.fetch("repositories")
    assert_empty items[2].fetch("physical_locations").sole.fetch("identifiers")
    assert_equal "javascript:item_bad()", items.first.fetch("links").sole.fetch("attributes").fetch("target")

    get work_url(work)
    assert_response :success
    stub = source_dom("stub")
    assert_represented_caption stub, 3
    assert_equal %w[first second third], stub.css("[data-item-xml-id]").map { |item| item["data-item-xml-id"] }
    assert_match(/Repository and location identifiers are not supplied/, stub.at_css("[data-item-xml-id='second']").text)
    assert_match(/Repository not supplied/, stub.at_css("[data-item-xml-id='third']").text)
    assert_match(/does not establish a held copy or location/, stub.at_css("[data-item-xml-id='second'] .item-state").text)
    placeholder = source_dom("placeholder")
    assert_represented_caption placeholder, 0
    assert_equal ABSENCE_SENTENCE, empty_item_message(placeholder)
    assert_select "#catalogue-sources script, #catalogue-sources img, #catalogue-sources a[href^='javascript:']", count: 0
    assert_includes response.body, "&lt;script&gt;source_bad()&lt;/script&gt;"
    assert_includes response.body, "&lt;img src=x onerror=bad()&gt;"
    assert_includes stub.text, "javascript:item_bad()"
  end

  test "c7 item availability GETs use stored facts without source file access or XML parsing" do
    work = import_work("c2_missing_id_only", key: "F2R1-c7-no-read")
    directory = @retained_input_directory
    file_methods = %i[read binread open]
    originals = file_methods.to_h { |name| [name, File.method(name)] }
    parser = Mei::InputDocument.method(:new)
    file_methods.each do |name|
      original = originals.fetch(name)
      File.define_singleton_method(name) do |*args, **kwargs, &block|
        path = args.first
        if path.respond_to?(:to_path) || path.is_a?(String)
          expanded = File.expand_path(path.respond_to?(:to_path) ? path.to_path : path)
          raise "GET must not access source files" if expanded == directory || expanded.start_with?(directory + File::SEPARATOR)
        end
        original.call(*args, **kwargs, &block)
      end
    end
    Mei::InputDocument.define_singleton_method(:new) { |*| raise "GET must not parse XML" }

    data = source_api(work)
    assert_item_counts data, actual: 1, represented: 0, unsupported: 1, state: "partial"
    get work_url(work)
    assert_response :success
    source = source_dom("stub")
    assert_represented_caption source, 0
    assert_record_wide_unsupported_message source
  ensure
    originals&.each { |name, original| File.define_singleton_method(name, original) }
    Mei::InputDocument.define_singleton_method(:new, parser) if parser
  end

  private

  def source_api(work)
    get api_work_url(work, format: :json)
    assert_response :success
    data = JSON.parse(response.body).fetch("catalogue_sources")
    assert_equal %w[descriptions document projection], data.keys.sort
    data
  end

  def assert_item_counts(data, actual:, represented:, unsupported:, state:)
    summary = data.fetch("projection").fetch("summary")
    assert_equal state, summary.fetch("state")
    assert_equal actual, summary.fetch("item_nodes")
    assert_equal represented, summary.fetch("represented_items")
    assert_equal unsupported, summary.fetch("unsupported_items")
    assert_equal represented, data.fetch("descriptions").sum { |source| source.fetch("held_items").length }
  end

  def source_dom(xml_id)
    source = Nokogiri::HTML5(response.body).at_css("#catalogue-sources details[data-source-xml-id='#{xml_id}']")
    assert_not_nil source, "Expected exact source container #{xml_id}"
    source
  end

  def assert_represented_caption(source, count)
    caption = source.at_xpath("./summary").text.squish
    assert_match(/— #{count} represented item nodes;/, caption)
    refute_match(/— #{count} item nodes;/, caption)
  end

  def empty_item_message(source)
    source.xpath("./p").map { |paragraph| paragraph.text.squish }.find { |text| text.start_with?("No held-item") }.to_s
  end

  def assert_record_wide_unsupported_message(source)
    message = empty_item_message(source)
    assert_includes message, REPRESENTED_EMPTY
    assert_includes message, "This catalogue record contains unsupported item nodes"
    assert_includes message, "Unsupported or unresolved details"
    refute_includes message, ABSENCE_SENTENCE
    refute_match(/this (?:source|description) contains unsupported/i, message)
  end

  def import_work(fixture_name, key: "F2R1-#{fixture_name}")
    @retained_input_directory = Dir.mktmpdir("www-f2r1-source-detail-")
    File.write(File.join(@retained_input_directory, "record.xml"), <<~XML)
      <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1" xml:id="document">
        <meiHead><workList><work xml:id="work"><identifier label="CNW">#{key}</identifier><title>F2-R1 interface work</title></work></workList>
          <manifestationList>#{SYNTHETIC_SOURCES.fetch(fixture_name)}</manifestationList>
        </meiHead>
      </mei>
    XML
    result = Mei::Importer.new(directory: @retained_input_directory).call
    assert_equal 1, result.successes, result.inspect
    assert_equal 0, result.failures, result.inspect
    CatalogueDocument.find_by!(input_profile: "official_cnw_v401", catalogue: "CNW", record_key: key).work
  end
end
