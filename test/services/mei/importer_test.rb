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

      {
        "CNW 18" => ["1905-1906", 1905],
        "CNW 29" => ["1914-1916", 1914],
        "CNW 2" => ["1921", 1921],
        "CNW 34" => ["1903", 1903]
      }.each do |catalogue_number, (composition_date, composition_year)|
        fixture_work = Work.find_by!(catalogue_number: catalogue_number)
        assert_equal composition_date, fixture_work.composition_date
        assert_equal composition_year, fixture_work.composition_year
      end
    end

    test "updates existing imported works instead of duplicating them" do
      importer = Importer.new(directory: Rails.root.join("data/mei_samples"))
      importer.call

      assert_no_difference ["Work.count", "Composer.count", "CatalogueIdentifier.count"] do
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

    test "selects a direct work contributor with the composer role ahead of editorial metadata and other roles" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead>
            <fileDesc><titleStmt>
              <title>Header title</title>
              <respStmt><persName role="editor">Niels Bo Foltmann</persName></respStmt>
            </titleStmt></fileDesc>
            <workList><work xml:id="direct-contributor-composer">
              <title>Direct contributor composer</title>
              <contributor><persName role="author">An Author</persName></contributor>
              <contributor><persName role="translator">A Translator</persName></contributor>
              <contributor><persName role="composer">  Carl   Nielsen  </persName></contributor>
              <contributor><persName role="dedicatee">A Dedicatee</persName></contributor>
            </work></workList>
          </meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Carl Nielsen", Work.find_by!(source_identifier: "direct-contributor-composer").composer.name
      assert_not_includes result.warnings, "Missing composer; imported as Unknown composer"
      assert_not Composer.exists?(name: "Niels Bo Foltmann")
    end

    test "matches a direct work composer role case-insensitively" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="mixed-case-composer-role">
            <title>Mixed-case composer role</title>
            <contributor><persName role="CoMpOsEr">Case Preserved Name</persName></contributor>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Case Preserved Name", Work.find_by!(source_identifier: "mixed-case-composer-role").composer.name
      assert_not_includes result.warnings, "Missing composer; imported as Unknown composer"
    end

    test "does not select composer contributors beneath expressions or performances" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead>
            <fileDesc><titleStmt>
              <title>Header title</title>
              <composer><persName>Fixture Composer</persName></composer>
            </titleStmt></fileDesc>
            <workList><work xml:id="nested-composer-contributors">
              <title>Nested composer contributors</title>
              <expression><contributor><persName role="composer">Expression Composer</persName></contributor></expression>
              <performance><contributor><persName role="composer">Performance Composer</persName></contributor></performance>
            </work></workList>
          </meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Fixture Composer", Work.find_by!(source_identifier: "nested-composer-contributors").composer.name
      assert_not Composer.exists?(name: "Expression Composer")
      assert_not Composer.exists?(name: "Performance Composer")
    end

    test "supports a direct work composer element fallback" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="direct-composer-element">
            <title>Direct composer element</title>
            <composer><persName>Direct Element Composer</persName></composer>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Direct Element Composer", Work.find_by!(source_identifier: "direct-composer-element").composer.name
    end

    test "supports the titleStmt composer fixture fallback" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead>
            <fileDesc><titleStmt>
              <title>Fixture-compatible title</title>
              <composer><persName>Title Statement Composer</persName></composer>
            </titleStmt></fileDesc>
            <workList><work xml:id="title-statement-composer"><title>Work title</title></work></workList>
          </meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Title Statement Composer", Work.find_by!(source_identifier: "title-statement-composer").composer.name
    end

    test "does not accept a composer from a nested non-header titleStmt" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="nested-title-statement-composer">
            <title>Nested title statement composer</title>
            <expression>
              <titleStmt><composer><persName>Nested Title Statement Composer</persName></composer></titleStmt>
            </expression>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "nested-title-statement-composer")
      assert_equal "Unknown composer", work.composer.name
      assert_includes result.warnings, "Missing composer; imported as Unknown composer"
      assert_not Composer.exists?(name: "Nested Title Statement Composer")
    end

    test "uses Unknown composer with a warning when only editorial responsibility exists" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead>
            <fileDesc><titleStmt>
              <title>Editorial metadata only</title>
              <respStmt><persName role="editor">Header Editor</persName></respStmt>
            </titleStmt></fileDesc>
            <workList><work xml:id="editor-only"><title>Editor only</title></work></workList>
          </meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal "Unknown composer", Work.find_by!(source_identifier: "editor-only").composer.name
      assert_includes result.warnings, "Missing composer; imported as Unknown composer"
      assert_not Composer.exists?(name: "Header Editor")
    end

    test "selects a direct work creation date and derives its exact year" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="direct-exact-date">
            <title>Direct exact date</title>
            <creation><date isodate="1895">1895</date></creation>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "direct-exact-date")
      assert_equal "1895", work.composition_date
      assert_equal 1895, work.composition_year
      assert_not_includes result.warnings, "Missing composition date or year"
    end

    test "selects the direct work date instead of an earlier nested bibliography date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="direct-over-bibliography">
            <title>Direct over bibliography</title>
            <bibl><creation><date isodate="1913-04-29">1913-04-29</date></creation></bibl>
            <creation><date isodate="1924">1924</date></creation>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "direct-over-bibliography")
      assert_equal "1924", work.composition_date
      assert_equal 1924, work.composition_year
      assert_not_includes result.warnings, "Missing composition date or year"
    end

    test "does not select a nested bibliography-only date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="bibliography-only-date">
            <title>Bibliography only date</title>
            <bibl><creation><date isodate="1913-04-29">1913-04-29</date></creation></bibl>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "bibliography-only-date")
      assert_nil work.composition_date
      assert_nil work.composition_year
      assert_includes result.warnings, "Missing composition date or year"
    end

    test "does not select expression-only or performance-only dates" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="nested-structural-dates">
            <title>Nested structural dates</title>
            <expression><creation><date isodate="1901">1901</date></creation></expression>
            <performance><event><date isodate="1902-03-04">1902-03-04</date></event></performance>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "nested-structural-dates")
      assert_nil work.composition_date
      assert_nil work.composition_year
      assert_includes result.warnings, "Missing composition date or year"
    end

    test "retains a direct ranged date and the existing bounded year behavior" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="direct-ranged-date">
            <title>Direct ranged date</title>
            <creation><date notbefore="1920" notafter="1921">1920–21</date></creation>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      work = Work.find_by!(source_identifier: "direct-ranged-date")
      assert_equal "1920–21", work.composition_date
      assert_equal 1920, work.composition_year
      assert_not_includes result.warnings, "Missing composition date or year"
    end

    test "supports direct composition-labelled date fallbacks" do
      type_result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="typed-composition-date">
            <title>Typed composition date</title>
            <date type="composition" isodate="1888">1888</date>
          </work></workList></meiHead>
        </mei>
      XML
      label_result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="labelled-composition-date">
            <title>Labelled composition date</title>
            <date label="composition" isodate="1889">1889</date>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, type_result.successes
      assert_equal 1, label_result.successes
      typed_work = Work.find_by!(source_identifier: "typed-composition-date")
      labelled_work = Work.find_by!(source_identifier: "labelled-composition-date")
      assert_equal ["1888", 1888], [typed_work.composition_date, typed_work.composition_year]
      assert_equal ["1889", 1889], [labelled_work.composition_date, labelled_work.composition_year]
      assert_not_includes type_result.warnings, "Missing composition date or year"
      assert_not_includes label_result.warnings, "Missing composition date or year"
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
