require "test_helper"

# Controlled synthetic presentation cases. These are developer checks, not
# participant observations or a new source-import oracle.
class F3WorksInterfaceTest < ActionDispatch::IntegrationTest
  test "identical stored titles have distinct visible catalogue link names and detail context" do
    first = synthetic_work("same-first", title: "F3 same title", number: "29", year: 1901)
    second = synthetic_work("same-second", title: "F3 same title", number: "129", year: 1902)
    first.catalogue_identifiers.create!(identifier_type: "CNW", value: "29")
    second.catalogue_identifiers.create!(identifier_type: "CNW", value: "129")

    get works_url, params: { q: "F3 same title" }
    assert_response :success
    assert_select "a.work-result-link[href=?]", work_path(first), text: "F3 same title (CNW 29)"
    assert_select "a.work-result-link[href=?]", work_path(second), text: "F3 same title (CNW 129)"
    assert_select "table.works-table", text: /1901/
    assert_select "table.works-table", text: /1902/
    [first, second].each do |work|
      get work_url(work)
      assert_response :success
      assert_select "h1", text: "F3 same title"
      assert_select ".work-context .catalogue-cue", text: "CNW #{work.catalogue_number}"
      assert_select ".work-context", text: /#{work.composition_year}/
      assert_select ".work-context", text: /#{Regexp.escape(work.composer.name)}/
    end
  end

  test "catalogue cues use typed identity or known document family without inventing CNW" do
    cases = [
      ["bare", "29", nil, nil, "Catalogue: 29"],
      ["missing", nil, nil, nil, "Catalogue: Unknown"],
      ["cnw", "29", ["CNW", "29"], nil, "CNW 29"],
      ["prefixed", "29", ["cnw", "CNW 29"], nil, "CNW 29"],
      ["opus", "29", ["Opus", "29"], nil, "Opus: 29"],
      ["document", "29", nil, "CNW", "CNW 29"],
      ["other-document", "29", nil, "Other", "Catalogue: 29"],
      ["missing-document", nil, nil, "CNW", "Catalogue: Unknown"],
      ["typed-precedence", "29", ["Opus", "29"], "CNW", "Opus: 29"]
    ]
    cases.each do |key, number, typed, family, expected|
      work = synthetic_work(key, number: number)
      work.catalogue_identifiers.create!(identifier_type: typed.first, value: typed.last) if typed
      work.update!(catalogue_document: synthetic_document(key, family)) if family
      get work_url(work)
      assert_response :success
      assert_select ".work-context .catalogue-cue", text: expected
      assert_select "h1", text: work.title
    end
  end

  test "instrumentation explanations match only the verified whole source strings and stay escaped" do
    work = synthetic_work("instrumentation")
    known = { "1 pf." => "one piano", "1 vl." => "one violin" }
    unknown = ["pf.", "vl.", "2 pf.", "1 PF.", "1 pf", "1 pf. ", "1 pf., 1 vl.", "1 pf. / 1 vl.", "1 voice", "<script>unknown</script>"]
    (known.keys + unknown).each { |name| work.instrumentations.create!(name: name) }

    [works_url(q: work.title), work_url(work)].each do |url|
      get url
      assert_response :success
      assert_select ".instrumentation-source", count: known.size + unknown.size do |nodes|
        by_source = nodes.to_h { |node| [node.text, node.parent.at_css(".instrumentation-explanation").text] }
        known.each { |raw, meaning| assert_equal "— #{meaning}", by_source.fetch(raw) }
        unknown.each { |raw| assert_equal "— Explanation unavailable for this source wording.", by_source.fetch(raw) }
      end
      assert_select ".instrumentation-list script", count: 0
      assert_includes response.body, "&lt;script&gt;unknown&lt;/script&gt;"
    end
  end

  test "guidance describes actual typed catalogue and raw instrumentation filtering" do
    exact = synthetic_work("filter-exact", number: "29")
    fragment = synthetic_work("filter-fragment", number: "129")
    exact.catalogue_identifiers.create!(identifier_type: "CNW", value: "29")
    exact.instrumentations.create!(name: "1 pf.")
    fragment.instrumentations.create!(name: "1 vl.")

    get works_url, params: { q: "F3 UI", catalogue_number: "CNW 29" }
    assert_response :success
    assert_select "table.works-table tbody tr", count: 1
    assert_select ".work-result-link[href=?]", work_path(exact)
    assert_select "#q-hint", text: "Search title variants, composer and catalogue text."
    assert_select "#catalogue_number-hint", text: /CNW 29 matches that typed identifier exactly/
    assert_select "#instrumentation-hint", text: /Match source wording, for example 1 pf./
    assert_select "#filter-guidance", text: /Filters combine/

    get works_url, params: { q: "F3 UI", catalogue_number: "29" }
    assert_select "table.works-table tbody tr", count: 2
    get works_url, params: { q: "F3 UI", instrumentation: "1 pf." }
    assert_select "table.works-table tbody tr", count: 1
    assert_select ".work-result-link[href=?]", work_path(exact)
    get works_url, params: { q: "F3 UI", instrumentation: "one piano" }
    assert_select "table.works-table", count: 0
    assert_select ".result-count", text: /No works match/
  end

  test "invalid HTML filters return field errors and safe scalar values without success results" do
    [
      [{ year_from: "19x", q: "<script>input</script>" }, "year_from", "19x"],
      [{ year_from: "2000", year_to: "1900" }, "year_to", "1900"],
      [{ year_to: ["1900"] }, "year_to", nil],
      [{ per_page: "" }, "per_page", ""]
    ].each do |filters, field, retained|
      get works_url, params: filters
      assert_response :bad_request
      assert_select ".filter-errors[role=alert]", text: /No search was run/
      assert_select "##{field}[aria-invalid=true]"
      assert_select "##{field}-error"
      assert_select "##{field}[value=?]", retained unless retained.nil?
      assert_select "table.works-table", count: 0
      assert_select ".result-count", count: 0
      assert_select "script", text: "input", count: 0
    end
    get works_url, params: { page: "two" }
    assert_response :bad_request
    assert_select ".filter-errors", text: /Requested page: two/
  end

  test "HTML pagination reports filtered ranges preserves navigation and resets form or Clear" do
    5.times { |index| synthetic_work("page-#{index}", title: "F3 page #{index}", year: 1900 + index) }
    filters = { q: "F3 page", year_from: "1900", per_page: "2", page: "2" }
    get works_url, params: filters
    assert_response :success
    assert_select ".result-count", text: "Showing 3–4 of 5 works."
    assert_select ".pagination[aria-label='Works pages'] a[rel=prev]" do |links|
      assert_equal({ "q" => "F3 page", "year_from" => "1900", "per_page" => "2", "page" => "1" }, Rack::Utils.parse_query(URI.parse(links.first["href"]).query))
    end
    assert_select ".pagination a[rel=next]", text: "Next page"
    assert_select "form input[name=page]", count: 0
    assert_select "form input[name=commit]", count: 0
    assert_select "form input#per_page[value='2']"
    assert_select "form a[href=?]", works_path, text: "Clear"

    get works_url, params: filters.merge(page: "4")
    assert_response :success
    assert_select ".result-count", text: "Page 4 has no works. 5 works match the filters across 3 pages. Use First page or Last page below."
    assert_select ".pagination a[rel=first]", count: 1
    assert_select ".pagination a[rel=last]", count: 1
    assert_select ".pagination a[rel=prev], .pagination a[rel=next]", count: 0
    get works_url, params: { q: "F3 nonexistent page" }
    assert_select ".result-count", text: /No works match/
    assert_select ".pagination", count: 0
  end

  test "detail inspection links reach retained sections and provenance remains plain text" do
    work = synthetic_work("inspection")
    get work_url(work)
    assert_response :success
    %w[title-variants work-classifications instrumentation catalogue-sources].each do |id|
      assert_select ".inspection-nav a[href=?]", "##{id}", count: 1
      assert_select "##{id}", count: 1
    end
    assert_select ".metadata dt", text: "Imported file/reference identifier"
    assert_select ".metadata dd.trace", text: work.source_file
    assert_select ".metadata a", count: 0
    assert_select "#catalogue-sources", text: /presence or absence is unknown/
    assert_select "#catalogue-availability", text: /Legacy data/
    assert_select "#instrumentation", text: /Instrumentation is not supplied/
  end

  private

  def synthetic_work(key, title: "F3 UI #{key}", number: nil, year: nil)
    Work.create!(title: title, composer: composers(:one), catalogue_number: number,
      composition_year: year, source_file: "test/generated/f3-interface/#{key}.xml")
  end

  def synthetic_document(key, family)
    CatalogueDocument.create!(input_profile: "demo", catalogue: family,
      record_key: "f3-interface-#{key}", committed_sha256: "f" * 64,
      origin_relative_name: "#{key}.xml")
  end
end
