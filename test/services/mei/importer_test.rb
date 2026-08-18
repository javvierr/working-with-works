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

      {
        "CNW 18" => [Date.new(1906, 11, 11), "Copenhagen", "Royal Danish Theatre"],
        "CNW 29" => [Date.new(1916, 2, 1), "Copenhagen", "Musikforeningen"],
        "CNW 2" => [Date.new(1922, 7, 8), "Odense", "Sample choral society"],
        "CNW 34" => [Date.new(1903, 10, 8), "Copenhagen", "Royal Danish Orchestra"]
      }.each do |catalogue_number, expected_values|
        performance = Work.find_by!(catalogue_number: catalogue_number).performances.sole
        assert_equal expected_values, [performance.performed_on, performance.location, performance.performers]
      end

      {
        "CNW 18" => ["LOAR dataset context", "https://loar.kb.dk/"],
        "CNW 29" => ["Royal Danish Library catalogue context", "https://www.kb.dk/"],
        "CNW 2" => ["Royal Danish Library", "https://www.kb.dk/en"],
        "CNW 34" => ["LOAR thematic catalogue dataset context", "https://loar.kb.dk/"]
      }.each do |catalogue_number, expected_values|
        reference = Work.find_by!(catalogue_number: catalogue_number).external_references.sole
        assert_equal expected_values, [reference.label, reference.url]
      end
    end

    test "updates existing imported works instead of duplicating them" do
      importer = Importer.new(directory: Rails.root.join("data/mei_samples"))
      importer.call

      assert_no_difference ["Work.count", "Composer.count", "CatalogueIdentifier.count", "Performance.count", "ExternalReference.count"] do
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

    test "imports an untyped event from a normalized performances event list with its exact direct date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="parent-typed-performance-event">
            <title>Parent-typed performance event</title>
            <history><eventList type="  PeRfOrMaNcEs  ">
              <event><date isodate=" 1896-01-15 "> 1896-01-15 </date></event>
            </eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "parent-typed-performance-event").performances.sole
      assert_equal Date.new(1896, 1, 15), performance.performed_on
      assert_not_includes result.warnings, "No performance information found"
    end

    test "uses a direct event date instead of an earlier nested review date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="direct-performance-date">
            <title>Direct performance date</title>
            <history><eventList type="performances"><event>
              <biblList><bibl><date isodate="1896-01-16">1896-01-16</date></bibl></biblList>
              <date isodate="1896-01-15">1896-01-15</date>
            </event></eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "direct-performance-date").performances.sole
      assert_equal Date.new(1896, 1, 15), performance.performed_on
    end

    test "does not use a nested-only review date as the performance date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="nested-only-performance-date">
            <title>Nested-only performance date</title>
            <history><eventList type="performances"><event>
              <biblList><bibl><date isodate="1896-01-16">1896-01-16</date></bibl></biblList>
              <desc>Direct event description</desc>
            </event></eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "nested-only-performance-date").performances.sole
      assert_nil performance.performed_on
      assert_equal "Direct event description", performance.note
      assert_not_includes result.warnings, "Non-exact performance date was not stored"
    end

    test "flattens direct event locations and role-bearing participants while excluding nested review values" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="bounded-performance-fields">
            <title>Bounded performance fields</title>
            <history><eventList type="performances"><event>
              <geogName role="venue">The Royal Theatre</geogName>
              <geogName role="place">Copenhagen</geogName>
              <persName role="conductor">Ebbe Hamerik</persName>
              <corpName role="ensemble">Royal Orchestra</corpName>
              <desc>First performance.</desc>
              <biblList><bibl>
                <geogName role="place">Nested Review Place</geogName>
                <persName role="reviewer">Nested Reviewer</persName>
                <corpName role="publisher">Nested Publisher</corpName>
                <desc>Nested review description</desc>
              </bibl></biblList>
            </event></eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "bounded-performance-fields").performances.sole
      assert_equal "Venue: The Royal Theatre; Place: Copenhagen", performance.location
      assert_equal "Ebbe Hamerik (conductor), Royal Orchestra (ensemble)", performance.performers
      assert_equal "First performance.", performance.note
      assert_not_includes performance.location, "Nested Review Place"
      assert_not_includes performance.performers, "Nested Reviewer"
      assert_not_includes performance.note, "Nested review description"
    end

    test "skips a blank performance event with one accounted warning" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="blank-performance-event">
            <title>Blank performance event</title>
            <history><eventList type="performances"><event/></eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal 0, Work.find_by!(source_identifier: "blank-performance-event").performances.count
      assert_equal 1, result.warnings.count("Skipped performance event with no supported direct values")
      assert_equal 0, result.warnings.count("No performance information found")
    end

    test "retains other direct fields while refusing to coerce a ranged performance date" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="ranged-performance-date">
            <title>Ranged performance date</title>
            <history><eventList type="performances"><event>
              <date startdate="1920" enddate="1921">1920–21</date>
              <geogName role="venue">Concert Hall</geogName>
            </event></eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "ranged-performance-date").performances.sole
      assert_nil performance.performed_on
      assert_equal "Venue: Concert Hall", performance.location
      assert_equal 1, result.warnings.count("Non-exact performance date was not stored")
      assert_equal 0, result.warnings.count("Skipped performance event with no supported direct values")
    end

    test "retains no-performance warning only for a work with no candidate events" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="no-performance-events">
            <title>No performance events</title>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal 0, Work.find_by!(source_identifier: "no-performance-events").performances.count
      assert_equal 1, result.warnings.count("No performance information found")
      assert_equal 0, result.warnings.count("Skipped performance event with no supported direct values")
    end

    test "stores separate rows for source events with equal mapped values" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="equal-performance-events">
            <title>Equal performance events</title>
            <history><eventList type="performances">
              <event><date isodate="1924-02-10">1924-02-10</date><geogName>Odense</geogName></event>
              <event><date isodate="1924-02-10">1924-02-10</date><geogName>Odense</geogName></event>
            </eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performances = Work.find_by!(source_identifier: "equal-performance-events").performances
      assert_equal 2, performances.count
      assert_equal [Date.new(1924, 2, 10), Date.new(1924, 2, 10)], performances.order(:id).pluck(:performed_on)
      assert_equal ["Odense", "Odense"], performances.order(:id).pluck(:location)
    end

    test "retains the legacy performance element compatibility form with only direct values" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="legacy-performance-element">
            <title>Legacy performance element</title>
            <history><performance>
              <date isodate="1922-07-08">8 July 1922</date>
              <geogName>Odense</geogName>
              <corpName role="ensemble">Legacy Ensemble</corpName>
              <note>Legacy note</note>
            </performance></history>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      performance = Work.find_by!(source_identifier: "legacy-performance-element").performances.sole
      assert_equal Date.new(1922, 7, 8), performance.performed_on
      assert_equal "Odense", performance.location
      assert_equal "Legacy Ensemble (ensemble)", performance.performers
      assert_equal "Legacy note", performance.note
    end

    test "imports and replaces a bounded generated set of performance events without duplication" do
      events = 30.times.map do |index|
        day = (index % 28) + 1
        <<~XML
          <event>
            <date isodate="1924-02-#{day.to_s.rjust(2, "0")}">1924-02-#{day.to_s.rjust(2, "0")}</date>
            <desc>Generated performance #{index + 1}</desc>
          </event>
        XML
      end.join
      xml = <<~XML
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="generated-performance-events">
            <title>Generated performance events</title>
            <history><eventList type="performances">#{events}</eventList></history>
          </work></workList></meiHead>
        </mei>
      XML

      Dir.mktmpdir("mei-importer-", Rails.root.join("tmp")) do |directory|
        Pathname.new(directory).join("record.xml").write(xml)
        importer = Importer.new(directory: directory)

        first_result = importer.call
        assert_equal 1, first_result.successes
        work = Work.find_by!(source_identifier: "generated-performance-events")
        assert_equal 30, work.performances.count

        assert_no_difference "Performance.count" do
          second_result = importer.call
          assert_equal 1, second_result.successes
        end
        assert_equal 30, work.reload.performances.count
        assert_equal 30, work.performances.distinct.count(:note)
      end
    end

    test "stores only syntactically absolute HTTP references from the bounded target elements" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="external-reference-contract">
            <title>External reference contract</title>
            <relation target="http://example.org/plain"><label>HTTP reference</label></relation>
            <ref target="https://example.org/secure">HTTPS reference</ref>
            <ptr target="   HtTpS://Example.org/Mixed   " rel="mixed-case"/>
            <relation target="https://example.org/record.xml" rel="xml-record"/>
            <relation target="https://example.org/search?work=18&amp;view=full" rel="query-record"/>
            <relation target="https://example.org/score.pdf#page=3" rel="fragment-record"/>

            <relation target="" rel="blank-target"/>
            <ptr target="   " rel="whitespace-only-target"/>
            <relation target="cnw0018.xml" rel="relative-xml"/>
            <relation target="document.xq?doc=cnw0018.xml" rel="query-style"/>
            <relation target="?doc=cnw0018.xml" rel="relative-query"/>
            <relation target="/dcm/assets/example.pdf" rel="root-relative"/>
            <relation target="#fragment" rel="fragment-only"/>
            <relation target="//example.org/path" rel="protocol-relative"/>
            <relation target="mailto:catalogue@example.org" rel="mail"/>
            <relation target="ftp://example.org/file" rel="ftp"/>
            <relation target="javascript:alert(1)" rel="javascript"/>
            <relation target="data:text/plain,example" rel="data"/>
            <relation target="https:///path" rel="hostless"/>
            <relation target="https://example.org/bad path" rel="whitespace"/>
            <relation target="https://example.org/%ZZ" rel="malformed"/>

            <graphic target="https://example.org/graphic.jpg"/>
            <persName auth.uri="https://example.org/authority">Authority name</persName>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal 0, result.failures
      assert_equal 0, ImportLog.where(status: "failure").count
      work = Work.find_by!(source_identifier: "external-reference-contract")
      assert_equal [
        ["HTTP reference", "http://example.org/plain"],
        ["HTTPS reference", "https://example.org/secure"],
        ["mixed-case", "HtTpS://Example.org/Mixed"],
        ["xml-record", "https://example.org/record.xml"],
        ["query-record", "https://example.org/search?work=18&view=full"],
        ["fragment-record", "https://example.org/score.pdf#page=3"]
      ], work.external_references.order(:id).pluck(:label, :url)
      assert_not_includes result.warnings, "No external references found"
      assert_not work.external_references.exists?(url: "https://example.org/graphic.jpg")
      assert_not work.external_references.exists?(url: "https://example.org/authority")
    end

    test "de-duplicates normalized external URLs while retaining the first source label" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="duplicate-external-reference">
            <title>Duplicate external reference</title>
            <relation target="  https://example.org/score.pdf  "><label>First label</label></relation>
            <ref target="https://example.org/score.pdf"><label>Second label</label></ref>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      reference = Work.find_by!(source_identifier: "duplicate-external-reference").external_references.sole
      assert_equal ["First label", "https://example.org/score.pdf"], [reference.label, reference.url]
      assert_not_includes result.warnings, "No external references found"
    end

    test "rejects internal-only targets with one no-external-references warning" do
      result = import_xml(<<~XML)
        <mei xmlns="http://www.music-encoding.org/ns/mei">
          <meiHead><workList><work xml:id="internal-only-references">
            <title>Internal-only references</title>
            <relation target="cnw0018.xml" rel="related-work"/>
            <ptr target="/dcm/assets/example.pdf" rel="local-asset"/>
          </work></workList></meiHead>
        </mei>
      XML

      assert_equal 1, result.successes
      assert_equal 0, Work.find_by!(source_identifier: "internal-only-references").external_references.count
      assert_equal 1, result.warnings.count("No external references found")
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
