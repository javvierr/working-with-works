require "test_helper"
require "tmpdir"

module Mei
  class ImporterTest < ActiveSupport::TestCase
    setup do
      ImportLog.delete_all
      Work.destroy_all
      Composer.destroy_all
    end

    test "imports sample MEI files into related records" do
      result = Importer.new(directory: Rails.root.join("data/mei_samples")).call

      assert_equal 4, result.files_seen
      assert_equal 4, result.successes
      assert_equal 0, result.failures
      assert_equal 4, Work.count
      assert_equal 1, Composer.count
      assert_equal 4, ImportLog.where(status: "success").count

      work = Work.find_by!(catalogue_number: "CNW 29")
      assert_equal "Symphony No. 4, The Inextinguishable", work.title
      assert_equal "Carl Nielsen", work.composer.name
      assert_equal 4, work.movements.count
      assert_operator work.instrumentations.count, :>=, 4
      assert_equal "data/mei_samples/cnw_29_symphony_no_4.mei", work.source_file
      assert work.source_references.any?
      assert work.performances.any?
      assert work.external_references.any?
    end

    test "updates existing imported works instead of duplicating them" do
      importer = Importer.new(directory: Rails.root.join("data/mei_samples"))
      importer.call

      assert_no_difference ["Work.count", "CatalogueIdentifier.count"] do
        importer.call
      end
      assert_equal 8, ImportLog.where(status: "success").count
    end

    test "selects the direct CNW identifier when another type appears first" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="opus-first">
            <title>Opus first</title>
            <identifier label="Opus">27</identifier>
            <identifier label="CNW">63</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "opus-first")
      assert_equal "63", work.catalogue_number
      assert_equal [["Opus", "27"], ["CNW", "63"]], work.catalogue_identifiers.order(:id).pluck(:identifier_type, :value)
    end

    test "selects a CNW-only identifier" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="cnw-only">
            <title>CNW only</title>
            <identifier label="cnw">417</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "417", Work.find_by!(source_identifier: "cnw-only").catalogue_number
    end

    test "falls back to the first identifier when no direct CNW identifier exists" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="no-cnw">
            <title>No CNW</title>
            <identifier label="Opus">9</identifier>
            <identifier label="FS">20</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "9", Work.find_by!(source_identifier: "no-cnw").catalogue_number
    end

    test "imports equal values under different identifier types" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="typed-duplicates">
            <title>Typed duplicate values</title>
            <identifier label="Opus">27</identifier>
            <identifier label="CNW">27</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal 0, result.failures
      work = Work.find_by!(source_identifier: "typed-duplicates")
      assert_equal "27", work.catalogue_number
      assert_equal [["Opus", "27"], ["CNW", "27"]], work.catalogue_identifiers.order(:id).pluck(:identifier_type, :value)
    end

    test "de-duplicates an exact repeated identifier pair" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="exact-duplicate">
            <title>Exact duplicate</title>
            <identifier label="CNW">70</identifier>
            <identifier label="CNW">70</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "exact-duplicate")
      assert_equal [["CNW", "70"]], work.catalogue_identifiers.pluck(:identifier_type, :value)
    end

    test "uses catalogue as the generic type for an untyped identifier" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="generic-identifier">
            <title>Generic identifier</title>
            <identifier>Legacy 1</identifier>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "generic-identifier")
      assert_equal "Legacy 1", work.catalogue_number
      assert_equal [["catalogue", "Legacy 1"]], work.catalogue_identifiers.pluck(:identifier_type, :value)
    end

    test "rolls back a work when a genuinely invalid child violates its constraint" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="invalid-child">
            <title>Invalid child</title>
            <identifier label="CNW">999</identifier>
            <movement n="1"><title>First</title></movement>
            <movement n="1"><title>Second</title></movement>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 0, result.successes
      assert_equal 1, result.failures
      assert_not Work.exists?(source_identifier: "invalid-child")
      assert_equal 0, CatalogueIdentifier.count
      assert_equal 0, Movement.count
      failure_log = ImportLog.find_by!(status: "failure")
      assert_nil failure_log.work_id
    end

    private

    def import_xml(xml)
      Dir.mktmpdir("mei-importer-", Rails.root.join("tmp")) do |directory|
        Pathname.new(directory).join("record.xml").write(xml)
        return Importer.new(directory: directory).call
      end
    end
  end
end
