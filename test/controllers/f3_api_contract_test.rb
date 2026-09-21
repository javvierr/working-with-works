require "test_helper"
require_relative "../support/f3_fixture_support"

class F3ApiContractTest < ActionDispatch::IntegrationTest
  setup do
    @truth = JSON.parse(File.read(Rails.root.join("test/fixtures/files/f3_synthetic_truth.json")))
    F3SyntheticFixture.load!(@truth)
    connection = ActiveRecord::Base.connection
    @ids = connection.select_all("SELECT id,source_file FROM works WHERE source_file LIKE 'synthetic/f3/%' ORDER BY title,id").to_a.to_h do |row|
      [File.basename(row.fetch("source_file"), ".xml"), row.fetch("id")]
    end
    @order = @truth.fetch("ordering").fetch("frozen_ordered_external_keys").map { |key| @ids.fetch(key) }
  end

  test "default remains array and bounds all current works" do
    get "/api/works"
    assert_response :ok
    assert_kind_of Array, body
    assert_equal 20, body.size
    assert_equal "50", response.headers["X-Total-Count"]
    assert_equal "1", response.headers["X-Page"]
    assert_equal "20", response.headers["X-Per-Page"]
    assert_equal "3", response.headers["X-Total-Pages"]
    assert_equal %w[catalogue_number composer composition_date composition_year genre id instrumentation source_file title], body.first.keys.sort
  end

  test "all seven filtered pages agree with frozen tie order and retain filters" do
    observed = []
    (1..7).each do |page|
      get "/api/works", params: { q: "F3", page: page, per_page: 7 }
      assert_response :ok
      assert_equal "48", response.headers["X-Total-Count"]
      assert_equal "7", response.headers["X-Total-Pages"]
      assert_equal @order[(page - 1) * 7, 7], body.map { |row| row.fetch("id") }
      observed.concat(body.map { |row| row.fetch("id") })
      response.headers.fetch("Link").scan(/<([^>]+)>/).flatten.each do |url|
        uri = URI.parse(url)
        assert_nil uri.host
        values = Rack::Utils.parse_query(uri.query)
        assert_equal "F3", values.fetch("q")
        assert_equal "7", values.fetch("per_page")
        assert_includes (1..7), values.fetch("page").to_i
      end
    end
    assert_equal @order, observed
    assert_equal 48, observed.uniq.size
  end

  test "one page empty results and beyond last have exact links" do
    get "/api/works", params: { q: "F3", per_page: 100 }
    assert_response :ok
    assert_equal @order, body.map { |row| row.fetch("id") }
    assert_nil response.headers["Link"]
    get "/api/works", params: { q: "unmatched unicorn", page: 99 }
    assert_response :ok
    assert_equal [], body
    assert_equal "0", response.headers["X-Total-Pages"]
    assert_nil response.headers["Link"]
    get "/api/works", params: { q: "F3", page: 4 }
    assert_response :ok
    assert_equal [], body
    assert_equal "48", response.headers["X-Total-Count"]
    assert_equal "4", response.headers["X-Page"]
    assert_equal '</api/works?page=1&per_page=20&q=F3>; rel="first", </api/works?page=3&per_page=20&q=F3>; rel="last"', response.headers["Link"]
  end

  test "numeric normalization and strict pagination boundaries" do
    get "/api/works", params: { q: "F3", page: " 0002 ", per_page: "0007" }
    assert_response :ok
    assert_equal "2", response.headers["X-Page"]
    assert_equal "7", response.headers["X-Per-Page"]
    assert_equal @order[7, 7], body.map { |row| row.fetch("id") }
    { "page" => 1_000_000, "per_page" => 100 }.each do |field, cap|
      ["", " ", "0", "-1", "1.5", "1e2", "2tail", "+2", (cap + 1).to_s].each do |value|
        get "/api/works", params: { field => value }
        assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => field, "message" => "must be a positive decimal integer between 1 and #{cap}."}]
      end
    end
  end

  test "raw shapes are not discarded by permitted parameter filtering" do
    %w[page per_page q catalogue_number instrumentation genre year_from year_to].each do |field|
      ["#{field}[]=value", "#{field}[nested]=value", field].each do |query|
        raw_get "/api/works", query
        assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => field, "message" => "must be a scalar string."}]
      end
    end
  end

  test "deterministic errors exclude unknown names and raw values" do
    raw_get "/api/works", "z=no-raw-echo&year_to=0&q[]=a&per_page=0&page=0&genre=#{'x' * 201}&%3Cscript%3E=other-secret"
    assert_error 400, "invalid_parameters", "Invalid request parameters.", [
      {"parameter" => "page", "message" => "must be a positive decimal integer between 1 and 1000000."},
      {"parameter" => "per_page", "message" => "must be a positive decimal integer between 1 and 100."},
      {"parameter" => "q", "message" => "must be a scalar string."},
      {"parameter" => "genre", "message" => "must be at most 200 characters."},
      {"parameter" => "year_to", "message" => "must be a decimal integer between 1 and 9999."},
      {"parameter" => "query", "message" => "contains unsupported parameters."}
    ]
    %w[no-raw-echo other-secret script SELECT /Users/].each { |value| assert_not_includes response.body, value }
  end

  test "scalar repeats follow observed framework order" do
    ["q=lunar&q=solar", "q[]=lunar&q=solar", "q[x]=lunar&q=solar"].each do |query|
      raw_get "/api/works", query
      assert_response :ok
      assert_equal expected_keys { |row| row.fetch("insertion_rank") % 4 == 0 }, body.map { |row| row.fetch("id") }
    end
    ["q=solar&q[]=lunar", "q=solar&q[x]=lunar"].each do |query|
      raw_get "/api/works", query
      assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => "query", "message" => "could not be parsed."}]
    end
  end

  test "text search variants composer literal wildcards and quotes retain meaning" do
    { "%" => %w[F3-W001 F3-W009], "_" => %w[F3-W002 F3-W010], "\\" => %w[F3-W003 F3-W011], "'" => %w[F3-W004 F3-W012], "duplicate-search amber" => %w[F3-W008] }.each do |query, keys|
      get "/api/works", params: { q: query }
      assert_response :ok
      assert_equal sorted_ids(keys), body.map { |row| row.fetch("id") }
    end
    get "/api/works", params: { q: " Composer Benoit ", per_page: 100 }
    assert_response :ok
    assert_equal expected_keys { |row| row.fetch("composer") == "F3 Composer Benoit" }, body.map { |row| row.fetch("id") }
    get "/api/works", params: { q: "' OR 1=1 --" }
    assert_response :ok
    assert_equal [], body
  end

  test "typed catalogue is exact and excludes other and missing families" do
    get "/api/works", params: { catalogue_number: " cNw   29 " }
    assert_response :ok
    # Baseline fixture is also correctly typed CNW 29.
    assert_equal (sorted_ids(%w[F3-W001 F3-W006 F3-W008]) + [works(:one).id]), body.map { |row| row.fetch("id") }
    get "/api/works", params: { catalogue_number: "CNW 0029" }
    assert_response :ok
    assert_equal [@ids.fetch("F3-W007")], body.map { |row| row.fetch("id") }
    get "/api/works", params: { q: "F3", catalogue_number: "29" }
    assert_response :ok
    assert_equal sorted_ids(%w[F3-W001 F3-W002 F3-W003 F3-W004 F3-W005 F3-W006 F3-W007 F3-W008 F3-W029]), body.map { |row| row.fetch("id") }
  end

  test "retained classifications raw instruments and inclusive years combine" do
    get "/api/works", params: { q: "F3", genre: "retained sacred", per_page: 100 }
    assert_response :ok
    assert_equal expected_keys { |row| row.fetch("insertion_rank") % 5 == 0 }, body.map { |row| row.fetch("id") }
    get "/api/works", params: { q: "F3", year_from: "001900", year_to: "1900" }
    assert_response :ok
    assert_equal sorted_ids(%w[F3-W020 F3-W047 F3-W048]), body.map { |row| row.fetch("id") }
    get "/api/works", params: { q: "Composer Ada", genre: "Chamber", instrumentation: "1 pf.", year_from: 1881, year_to: 1927 }
    assert_response :ok
    assert_equal sorted_ids(%w[F3-W001 F3-W013 F3-W025 F3-W037]), body.map { |row| row.fetch("id") }
  end

  test "blank filters unset and years validate without coercion" do
    get "/api/works", params: { q: " ", year_from: "", genre: "\t" }
    assert_response :ok
    assert_equal "50", response.headers["X-Total-Count"]
    %w[0 -1 1900tail 1900.5 19e2 10000].each do |year|
      get "/api/works", params: { year_from: year }
      assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => "year_from", "message" => "must be a decimal integer between 1 and 9999."}]
    end
    get "/api/works", params: { year_from: 1901, year_to: 1900 }
    assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => "year_to", "message" => "must be greater than or equal to year_from."}]
  end

  test "character limit uses characters after trimming" do
    get "/api/works", params: { q: "  #{'é' * 200}  " }
    assert_response :ok
    assert_equal [], body
    %w[q catalogue_number instrumentation genre].each do |field|
      get "/api/works", params: { field => "é" * 201 }
      assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => field, "message" => "must be at most 200 characters."}]
    end
  end

  test "format negotiation precedes parameter and identity validation" do
    [["/api/works.xml", "page=0"], ["/api/works.json", "format=html"], ["/api/works/not-an-id.xml", ""], ["/api/works/1.5", ""], ["/api/works", "format[]=json&page=0"]].each do |path, query|
      raw_get path, query
      assert_error 406, "not_acceptable", "Only JSON responses are supported.", []
    end
    raw_get "/api/works", "page=0", "text/plain"
    assert_error 406, "not_acceptable", "Only JSON responses are supported.", []
  end

  test "Accept uses positive quality specificity and allows ordinary browser ranges" do
    ["application/json", "application/json; charset=utf-8", "application/*", "*/*", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "application/json;q=0.5,*/*;q=0"].each do |accept|
      raw_get "/api/works", "", accept
      assert_response :ok
      assert_equal "application/json", response.media_type
    end
    ["text/html", "application/xml", "application/problem+json", "application/json;q=0", "application/json;q=0,*/*;q=1", "application/*;q=0,*/*;q=1", "application/json;q=1.5"].each do |accept|
      raw_get "/api/works", "", accept
      assert_error 406, "not_acceptable", "Only JSON responses are supported.", []
    end
  end

  test "detail identity errors are safe and query errors precede identity" do
    %w[0 -1 1e2 12tail 9223372036854775808 9223372036854775807].each do |id|
      get "/api/works/#{id}"
      assert_error 404, "not_found", "Resource not found.", []
    end
    get "/api/works/000#{@ids.fetch('F3-W001')}"
    assert_response :ok
    assert_equal @ids.fetch("F3-W001"), body.fetch("id")
    assert body.key?("sources")
    assert body.key?("catalogue_sources")
    assert_equal "legacy_unvalidated", body.dig("availability", "status")
    get "/api/works/not-an-id", params: { q: "solar" }
    assert_error 400, "invalid_parameters", "Invalid request parameters.", [{"parameter" => "query", "message" => "contains unsupported parameters."}]
    get "/api/not-a-real-route.xml"
    assert_error 404, "not_found", "Resource not found.", []
  end

  private

  def body = JSON.parse(response.body)

  def raw_get(path, query, accept = nil)
    headers = accept.nil? ? {} : { "Accept" => accept }
    get path, headers: headers, env: { "QUERY_STRING" => query }
  end

  def assert_error(status, code, message, details)
    assert_response status
    assert_equal "application/json", response.media_type
    assert_equal({"error" => {"code" => code, "message" => message, "details" => details}}, body)
    %w[X-Total-Count X-Page X-Per-Page X-Total-Pages Link].each { |header| assert_nil response.headers[header] }
  end

  def sorted_ids(keys)
    selected = keys.map { |key| @ids.fetch(key) }
    @order.select { |id| selected.include?(id) }
  end

  def expected_keys(&predicate)
    sorted_ids(@truth.fetch("rows").select(&predicate).map { |row| row.fetch("external_key") })
  end
end
