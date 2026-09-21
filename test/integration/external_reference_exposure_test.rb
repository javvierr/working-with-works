require "test_helper"
require "tmpdir"

class ExternalReferenceExposureTest < ActionDispatch::IntegrationTest
  setup do
    ImportLog.delete_all
    Work.destroy_all
    Composer.destroy_all
  end

  test "API and HTML details expose only accepted HTTP references" do
    result = import_xml(<<~XML)
      <mei xmlns="http://www.music-encoding.org/ns/mei">
        <meiHead><workList><work xml:id="mixed-reference-exposure">
          <title>Mixed reference exposure</title>
          <relation target="https://example.org/accepted-score.pdf"><label>Accepted score</label></relation>
          <relation target="cnw0018.xml"><label>Internal catalogue target</label></relation>
        </work></workList></meiHead>
      </mei>
    XML

    assert_equal 1, result.successes
    work = Work.find_by!(source_identifier: "mixed-reference-exposure")

    get api_work_url(work, format: :json)

    assert_response :success
    api_body = JSON.parse(response.body)
    assert_equal [
      {
        "label" => "Accepted score",
        "url" => "https://example.org/accepted-score.pdf"
      }
    ], api_body.fetch("external_references")
    assert_not_includes response.body, "Internal catalogue target"
    assert_not_includes response.body, "cnw0018.xml"

    get work_url(work)

    assert_response :success
    assert_select "a[href=?]", "https://example.org/accepted-score.pdf", text: "Accepted score", count: 1
    assert_select "a[href=?]", "cnw0018.xml", count: 0
    assert_not_includes response.body, "Internal catalogue target"
    assert_not_includes response.body, "cnw0018.xml"
  end

  private

  def import_xml(xml)
    Dir.mktmpdir("mei-importer-", Rails.root.join("tmp")) do |directory|
      Pathname.new(directory).join("record.xml").write(xml)
      return Mei::Importer.new(directory: directory, input_profile: "demo", fixture_key: "mixed-reference-exposure").call
    end
  end
end
