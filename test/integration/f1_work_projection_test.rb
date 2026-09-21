require "test_helper"

# Controlled persisted examples isolate presentation from the importer. The five
# title distinctions below are derived from the frozen CNW 277 development case;
# these synthetic records are not independent real-source import evidence.
class F1WorkProjectionTest < ActionDispatch::IntegrationTest
  test "detail exposes every ordered title and work term with source metadata" do
    work = projected_work
    add_title_rows(work)
    add_term_rows(work)

    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Serenade", body.fetch("title")
    assert_equal "Vocal music", body.fetch("genre")
    assert_equal ["Serenade", "Serenade", "See! Luften er stille", "The blue waves are sleeping", "Se! Luften er stille"], body.fetch("titles").map { |row| row.fetch("text") }
    assert_equal [nil, nil, "alternative", "alternative", "uniform"], body.fetch("titles").map { |row| row.fetch("source_type") }
    assert_equal %w[da en da en da], body.fetch("titles").map { |row| row.fetch("language") }
    assert_equal (1..5).to_a, body.fetch("titles").map { |row| row.fetch("source_order") }
    assert_equal [true, false, false, false, false], body.fetch("titles").map { |row| row.fetch("selected_for_display") }
    assert_equal "title_168N200AB", body.fetch("titles").first.fetch("xml_id")
    assert_equal "da", body.fetch("titles").first.fetch("attributes").fetch("{http://www.w3.org/XML/1998/namespace}lang")
    assert_equal "Vocal music", body.fetch("classification_terms").first.fetch("text")
    assert_equal ["Vocal music", "Song", "Song"], body.fetch("classification_terms").map { |row| row.fetch("text") }
    assert_equal "synthetic-authority", body.fetch("classification_terms").first.fetch("classification_metadata").fetch("attributes").fetch("authority")
    assert_equal "synthetic-scheme", body.fetch("classification_terms").last.fetch("term_list_metadata").first.fetch("attributes").fetch("classcode")
    assert_equal "main_untyped_uniform_alternative_subordinate_v1", body.fetch("display_title_policy").fetch("name")
    assert_equal "untyped/source_order", body.fetch("display_title_policy").fetch("selection_reason")
    assert_equal "official", body.fetch("availability").fetch("status")
    assert_nil body.fetch("latest_import_attempt")
    assert_nil body.fetch("last_successful_import")
    assert_not_includes response.body, "/private/tmp/f1-private-origin.xml"
  end

  test "HTML shows title distinctions classification metadata and official availability" do
    work = projected_work
    add_title_rows(work)
    add_term_rows(work)

    get work_url(work)
    assert_response :success
    assert_select "#catalogue-availability", text: /Official CNW input/
    assert_select "#title-variants ol > li", count: 5
    assert_select "#title-variants", text: /Type: alternative; language: en/
    assert_select "#title-variants", text: /title_168N200AB/
    assert_select "#title-variants", text: /Selected heading/
    assert_select "#title-variants", text: /without a preferred language/
    assert_select "#work-classifications ol > li", count: 3
    assert_select "#work-classifications", text: /synthetic-authority/
    assert_select "#work-classifications", text: /synthetic-scheme/
  end

  test "alternative and uniform title searches and second term filters return one work in both interfaces" do
    work = projected_work
    add_title_rows(work)
    add_term_rows(work)

    ["See! Luften er stille", "The blue waves are sleeping", "Se! Luften er stille", "Serenade"].each do |query|
      assert_single_work_in_both_interfaces(work, q: query)
    end
    assert_single_work_in_both_interfaces(work, genre: "Song")
    assert_single_work_in_both_interfaces(work, q: work.catalogue_number)
  end

  test "typed title search keeps all instruments in name order in both lists" do
    work = projected_work
    add_title_rows(work)
    ["1 voice", "1 pf."].each { |name| work.instrumentations.create!(name: name) }
    filters = { q: "See! Luften er stille" }

    get api_works_url(format: :json), params: filters
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [work.id], body.map { |row| row.fetch("id") }
    assert_equal ["1 pf.", "1 voice"], body.first.fetch("instrumentation")

    get works_url, params: filters
    assert_response :success
    assert_select "table.works-table tbody tr", count: 1
    assert_select "table.works-table a[href=?]", work_path(work), count: 1
    # F3 adds visible explanations; retain the original exact raw-value/order check.
    assert_select "table.works-table tbody td:last-child .instrumentation-source" do |values|
      assert_equal ["1 pf.", "1 voice"], values.map(&:text)
    end
  end

  test "literal title and classification wildcard characters do not broaden results" do
    literal = projected_work(key: "wild-literal", title: "100%_literal", genre: "Category%_literal")
    add_title(literal, text: "100%_literal", order: 1)
    add_term(literal, text: "Category%_literal", order: 1)
    decoy = projected_work(key: "wild-decoy", title: "100XYliteral", genre: "CategoryXYliteral")
    add_title(decoy, text: "100XYliteral", order: 1)
    add_term(decoy, text: "CategoryXYliteral", order: 1)

    assert_single_work_in_both_interfaces(literal, q: "%_")
    assert_single_work_in_both_interfaces(literal, genre: "%_")
  end

  test "demo detail is visibly non authoritative and missing classification is explicit" do
    work = projected_work(profile: "demo", genre: nil)
    add_title(work, text: "Serenade", order: 1)

    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "demo", body.fetch("availability").fetch("status")
    assert_equal "demo", body.fetch("availability").fetch("input_profile")
    assert_equal "missing", body.fetch("availability").fetch("classification_terms")
    assert_empty body.fetch("classification_terms")
    assert_nil body.fetch("genre")
    get work_url(work)
    assert_response :success
    assert_select "#catalogue-availability", text: /non-authoritative sample/
    assert_select "#work-classifications", text: /No work classification is supplied/
  end

  test "legacy scalar records remain unvalidated without invented title or term provenance" do
    work = works(:one)
    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "legacy_unvalidated", body.fetch("availability").fetch("status")
    assert_equal "unvalidated", body.fetch("availability").fetch("titles")
    assert_equal "unvalidated", body.fetch("availability").fetch("classification_terms")
    assert_empty body.fetch("titles")
    assert_empty body.fetch("classification_terms")
    assert_nil body.fetch("display_title_policy")
    assert_equal work.title, body.fetch("title")
    assert_single_work_in_both_interfaces(work, q: "Inextinguishable")
    get work_url(work)
    assert_select "#catalogue-availability", text: /Legacy data/
    assert_select "#title-variants", text: /not been validated/
    assert_select "#work-classifications", text: /legacy value/
  end

  test "missing official classification stays null and distinct from legacy unvalidated metadata" do
    work = projected_work(genre: nil)
    add_title(work, text: "Serenade", order: 1)
    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "official", body.fetch("availability").fetch("status")
    assert_equal "missing", body.fetch("availability").fetch("classification_terms")
    assert_nil body.fetch("genre")
    assert_empty body.fetch("classification_terms")
    get work_url(work)
    assert_response :success
    assert_select "#work-classifications", text: /No work classification is supplied/
    assert_select "#work-classifications", text: /Genre is unknown/
  end

  test "subordinate heading fallback is labelled and unknown title type remains visible and searchable" do
    work = projected_work(title: "For synthetic voices", reason: "subordinate/source_order", order: 2)
    add_title(work, text: "A text-source title", order: 1, source_type: "text_source")
    add_title(work, text: "For synthetic voices", order: 2, source_type: "subordinate")

    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal true, body.fetch("display_title_policy").fetch("subordinate_fallback")
    assert_equal [false, true], body.fetch("titles").map { |row| row.fetch("selected_for_display") }
    assert_single_work_in_both_interfaces(work, q: "A text-source title")
    get work_url(work)
    assert_select "#title-variants", text: /subordinate title as a fallback/
    assert_select "#title-variants", text: /text_source/
  end

  test "same time failure is latest even without work association and recovery keeps failure history" do
    work = projected_work
    add_title(work, text: "Serenade", order: 1)
    time = Time.utc(2026, 9, 19, 12, 0, 0)
    successful = record_attempt(work, status: "success", time: time)
    failed = record_attempt(work, status: "failure", time: time, work_association: nil, error: "A child record could not be stored")

    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal failed.id, body.fetch("latest_import_attempt").fetch("id")
    assert_equal "failure", body.fetch("latest_import_attempt").fetch("status")
    assert_equal "A child record could not be stored", body.fetch("latest_import_attempt").fetch("error_message")
    assert_equal successful.id, body.fetch("last_successful_import").fetch("id")
    get work_url(work)
    assert_response :success
    assert_select "#latest-import-attempt", text: /Status: failure/
    assert_select "#latest-import-attempt .import-error", text: /A child record could not be stored/
    assert_select "#last-successful-import", text: /Data retained from the successful import/

    recovered = record_attempt(work, status: "success", time: time)
    get api_work_url(work, format: :json)
    body = JSON.parse(response.body)
    assert_equal recovered.id, body.fetch("latest_import_attempt").fetch("id")
    assert_equal recovered.id, body.fetch("last_successful_import").fetch("id")
    assert ImportLog.exists?(failed.id)
    get work_url(work)
    assert_select "#latest-import-attempt", text: /Status: success/
  end

  test "unsafe diagnostics and internal ingest paths are not exposed and markup is not rendered" do
    work = projected_work
    add_title(work, text: "Serenade", order: 1)
    record_attempt(work, status: "failure", time: Time.current, error: "Failed /private/tmp/f1-private-input.xml\n<script>alert('synthetic')</script>")

    get api_work_url(work, format: :json)
    assert_response :success
    body = JSON.parse(response.body)
    assert body.fetch("latest_import_attempt").fetch("error_message").present?
    assert_not_includes response.body, "/private/tmp/f1-private-input.xml"
    assert_not_includes response.body, "/private/tmp/f1-private-origin.xml"
    assert_not_includes response.body, "<script>"
    get work_url(work)
    assert_response :success
    assert_select "#latest-import-attempt .import-error", count: 1
    assert_select "#latest-import-attempt script", count: 0
    assert_not_includes response.body, "/private/tmp/f1-private-input.xml"
  end

  test "unassociated failure cannot appear on an unrelated document and index stays an array" do
    work = projected_work
    add_title(work, text: "Serenade", order: 1)
    ImportLog.create!(source_file: "test/generated/unknown.xml", status: "failure", imported_at: Time.current, error_message: "Unknown input failed")
    get api_work_url(work, format: :json)
    assert_response :success
    assert_nil JSON.parse(response.body).fetch("latest_import_attempt")
    get api_works_url(format: :json), params: { q: "Serenade" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_kind_of Array, body
    assert_equal [work.id], body.map { |row| row.fetch("id") }
    assert_not body.first.key?("titles")
    assert_not body.first.key?("latest_import_attempt")
  end

  private

  def projected_work(key: "derived-277", profile: "official_cnw_v401", title: "Serenade", genre: "Vocal music", reason: "untyped/source_order", order: 1)
    document = CatalogueDocument.create!(
      input_profile: profile, catalogue: "CNW", record_key: key,
      raw_record_identifier: key, committed_sha256: "a" * 64,
      root_xml_id: "synthetic-document", mei_namespace: "http://www.music-encoding.org/ns/mei",
      mei_version: "4.0.1", origin_relative_name: "#{key}.xml",
      latest_successful_path: "/private/tmp/f1-private-origin.xml"
    )
    Work.create!(catalogue_document: document, composer: composers(:one), title: title,
      genre: genre, catalogue_number: "F1 #{key}", source_file: "test/generated/f1/#{key}.xml",
      source_identifier: "synthetic-work", display_title_reason: reason, display_title_order: order)
  end

  def add_title_rows(work)
    [
      ["Serenade", nil, "da", "title_168N200AB"],
      ["Serenade", nil, "en", "title_168N200AF"],
      ["See! Luften er stille", "alternative", "da", "title_168N200B4"],
      ["The blue waves are sleeping", "alternative", "en", "title_168N200B9"],
      ["Se! Luften er stille", "uniform", "da", "title_01767f87"]
    ].each_with_index do |(text, type, language, xml_id), index|
      add_title(work, text: text, source_type: type, language: language, xml_id: xml_id, order: index + 1)
    end
  end

  def add_title(work, text:, order:, source_type: nil, language: nil, xml_id: nil)
    work.work_titles.create!(text: text, raw_text: text, source_type: source_type, language: language,
      xml_id: xml_id, source_order: order,
      locator: "/m:mei[1]/m:meiHead[1]/m:workList[1]/m:work[1]/m:title[#{order}]",
      source_attributes: { "{http://www.w3.org/XML/1998/namespace}lang" => language, "type" => source_type }.compact)
  end

  def add_term_rows(work)
    %w[Vocal\ music Song Song].each_with_index { |text, index| add_term(work, text: text, order: index + 1) }
  end

  def add_term(work, text:, order:)
    work.work_classification_terms.create!(text: text, raw_text: text, source_order: order,
      xml_id: "synthetic-term-#{order}", source_attributes: { "type" => "genre" },
      locator: "/m:mei[1]/m:meiHead[1]/m:workList[1]/m:work[1]/m:classification[1]/m:termList[1]/m:term[#{order}]",
      classification_metadata: { "attributes" => { "authority" => "synthetic-authority" } },
      term_list_metadata: [{ "attributes" => { "classcode" => "synthetic-scheme" } }])
  end

  def record_attempt(work, status:, time:, work_association: work, error: nil)
    ImportLog.create!(catalogue_document: work.catalogue_document, work: work_association,
      source_file: work.source_file, observed_path: "/private/tmp/f1-private-origin.xml",
      status: status, imported_at: time, warnings: [], error_message: error,
      attempted_profile: work.catalogue_document.input_profile, attempted_catalogue: "CNW",
      attempted_record_key: work.catalogue_document.record_key, attempted_sha256: "a" * 64)
  end

  def assert_single_work_in_both_interfaces(work, filters)
    get api_works_url(format: :json), params: filters
    assert_response :success
    assert_equal [work.id], JSON.parse(response.body).map { |row| row.fetch("id") }
    get works_url, params: filters
    assert_response :success
    assert_select "table.works-table tbody tr", count: 1
    assert_select "table.works-table a[href=?]", work_path(work), count: 1
  end
end
