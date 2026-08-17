require "test_helper"

class ApiWorksTest < ActionDispatch::IntegrationTest
  test "index returns work summaries" do
    get api_works_url(format: :json)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body.size
    assert_equal "Carl Nielsen", body.first.fetch("composer").fetch("name")
    assert body.first.key?("instrumentation")
  end

  test "show returns nested catalogue data" do
    get api_work_url(works(:one), format: :json)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Symphony No. 4, The Inextinguishable", body.fetch("title")
    assert_equal ["CNW 29"], body.fetch("catalogue_identifiers").map { |identifier| identifier.fetch("value") }
    assert_equal ["Allegro"], body.fetch("movements").map { |movement| movement.fetch("title") }
    assert body.fetch("sources").any?
  end

  test "index filters by search term" do
    get api_works_url(format: :json), params: { q: "Helios" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal ["Helios Overture"], body.map { |work| work.fetch("title") }
  end

  test "index filters by instrumentation and year range" do
    get api_works_url(format: :json), params: { instrumentation: "strings", year_from: 1910, year_to: 1920 }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal ["CNW 29"], body.map { |work| work.fetch("catalogue_number") }
    assert_includes body.first.fetch("instrumentation"), "4 horns"
  end

  test "catalogue filter returns the same work for bare and prefixed CNW input" do
    get api_works_url(format: :json), params: { catalogue_number: "29" }
    assert_response :success
    bare_ids = JSON.parse(response.body).map { |work| work.fetch("id") }

    get api_works_url(format: :json), params: { catalogue_number: "  cNw   29  " }
    assert_response :success
    prefixed_ids = JSON.parse(response.body).map { |work| work.fetch("id") }

    assert_equal [works(:one).id], bare_ids
    assert_equal bare_ids, prefixed_ids
  end

  test "prefixed catalogue filter excludes equal values from another identifier family" do
    other_work = Work.create!(
      composer: composers(:one),
      title: "Non-CNW identifier",
      catalogue_number: "29",
      source_file: "test/generated/non-cnw-identifier.xml"
    )
    other_work.catalogue_identifiers.create!(identifier_type: "FS", value: "29")

    get api_works_url(format: :json), params: { catalogue_number: "CNW 29" }

    assert_response :success
    assert_equal [works(:one).id], JSON.parse(response.body).map { |work| work.fetch("id") }
  end
end
