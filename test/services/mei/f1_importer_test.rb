require "test_helper"
require "tmpdir"
require "digest"

module Mei
  class F1ImporterTest < ActiveSupport::TestCase
    setup do
      ImportLog.delete_all
      Work.destroy_all
      CatalogueDocument.delete_all
      Composer.destroy_all
    end

    test "official profile is strict about root namespace version direct work and CNW identity" do
      valid = official
      variants = {
        malformed: "<mei>",
        wrong_root: valid.sub("<mei ", "<other ").sub("</mei>", "</other>"),
        wrong_namespace: valid.gsub(InputDocument::MEI_NAMESPACE, "urn:wrong"),
        wrong_version: valid.sub('meiversion="4.0.1"', 'meiversion="4.0.0"'),
        missing_version: valid.sub('meiversion="4.0.1"', ''),
        no_work: valid.sub(/<work xml:id="synthetic-work">.*<\/work>/m, ''),
        two_works: valid.sub('</workList>', '<work><title>Second</title><identifier label="CNW">2</identifier></work></workList>'),
        nested_only_work: valid.sub('<work xml:id="synthetic-work">', '<wrapper><work xml:id="synthetic-work">').sub('</work></workList>', '</work></wrapper></workList>'),
        missing_cnw: valid.sub('<identifier label="CNW">001</identifier>', ''),
        blank_cnw: valid.sub('>001</identifier>', "> \t </identifier>"),
        multiple_cnw: valid.sub('</work>', '<identifier label="CNW">001</identifier></work>'),
        conflicting_family: valid.sub('label="CNW"', 'label="CNW" type="Opus"'),
        duplicate_xml_id: valid.sub('</work>', '<title xml:id="synthetic-work">Duplicate ID</title></work>'),
        dtd: '<!DOCTYPE mei [<!ENTITY secret "forbidden">]>' + valid,
        external_dtd: '<!DOCTYPE mei SYSTEM "file:///must-not-be-read">' + valid
      }
      variants.each do |label, xml|
        in_directory do |directory|
          before = domain_snapshot
          result = import(directory, xml)
          assert_equal [1, 0, 1], counts(result), label.to_s
          assert_equal before, domain_snapshot, label.to_s
          log = ImportLog.order(:id).last
          assert_nil log.work_id, label.to_s
          assert_nil log.catalogue_document_id, label.to_s
          assert_equal "official_cnw_v401", log.attempted_profile
          assert_not_includes log.error_message, directory
          assert_not_includes log.error_message, "<mei"
        end
      end
      in_directory { |directory| assert_equal [1, 1, 0], counts(import(directory, valid)) }
    end

    test "empty and missing directories produce honest run errors without invented file failures" do
      in_directory do |directory|
        [directory, File.join(directory, "missing")].each do |path|
          before = domain_snapshot
          logs = ImportLog.count
          result = Importer.new(directory: path).call
          assert_equal [0, 0, 0], counts(result)
          assert_equal 1, result.run_errors.length
          assert_not result.success?
          assert_equal logs, ImportLog.count
          assert_equal before, domain_snapshot
        end
      end
    end

    test "official identity preserves raw XML whitespace while normalizing only its key" do
      in_directory do |directory|
        xml = official(key: "  Coll.\t 27\n ")
        result = import(directory, xml)
        assert result.success?
        document = CatalogueDocument.sole
        assert_equal "Coll. 27", document.record_key
        assert_equal "  Coll.\t 27\n ", document.raw_record_identifier
        assert_equal "CNW", document.catalogue
        assert_equal "Coll. 27", document.work.catalogue_number
        assert_equal Digest::SHA256.hexdigest(xml), document.committed_sha256
      end
    end

    test "CNW family accepts matching label and type but rejects contradictory populated markers" do
      in_directory do |directory|
        xml = official.sub('label="CNW"', 'label="  cNw " type="CNW"')
        assert import(directory, xml).success?
        document = CatalogueDocument.sole
        assert_equal({ "label" => "  cNw ", "type" => "CNW" }, document.identifier_attributes)
        assert_equal "001", document.work.catalogue_number
      end
    end

    test "all duplicate batch members reject before writes while an independent identity succeeds" do
      [false, true].each do |changed_bytes|
        in_directory do |directory|
          first = official(key: "dup-#{changed_bytes}")
          second = changed_bytes ? first.sub('Original title', 'Competing title') : first
          File.write(File.join(directory, "a.xml"), first)
          File.write(File.join(directory, "b.xml"), second)
          File.write(File.join(directory, "c.xml"), official(key: "unique-#{changed_bytes}"))
          result = Importer.new(directory: directory).call
          assert_equal [3, 1, 2], counts(result)
          assert_not CatalogueDocument.exists?(record_key: "dup-#{changed_bytes}")
          assert CatalogueDocument.exists?(record_key: "unique-#{changed_bytes}")
          assert_equal 2, ImportLog.where(attempted_record_key: "dup-#{changed_bytes}", status: "failure").count
        end
      end
      in_directory do |directory|
        File.write(File.join(directory, "a.xml"), official(key: " spaced\t key "))
        File.write(File.join(directory, "b.xml"), official(key: "spaced key"))
        result = Importer.new(directory: directory).call
        assert_equal [2, 0, 2], counts(result)
        assert_not CatalogueDocument.exists?(record_key: "spaced key")
      end
    end

    test "same bytes at original or unclaimed relocated path retain work and child facts" do
      in_directory do |original|
        in_directory do |relocated|
          xml = official(body: '<title>Original title</title><movement n="1"><title>Movement</title></movement>')
          assert import(original, xml).success?
          document = CatalogueDocument.sole
          work = document.work
          facts = work_facts(work)
          assert import(original, xml).success?
          assert_equal facts, work_facts(work.reload)
          assert import(relocated, xml).success?
          assert_equal facts, work_facts(work.reload)
          assert_equal 1, CatalogueDocument.count
          assert_equal 1, Work.count
          assert_equal 3, document.import_logs.where(status: "success").count
          assert_equal File.realpath(File.join(relocated, "record.xml")), document.reload.latest_successful_path
          assert_equal 2, document.import_logs.where(status: "success").distinct.count(:observed_path)
        end
      end
    end

    test "changed bytes replace only at a previously successful path and preserve previous hash provenance" do
      in_directory do |directory|
        first = official
        second = first.sub('Original title', 'Allowed revision').sub('synthetic-work', 'changed-work-id').sub('synthetic-document', 'changed-root-id')
        assert import(directory, first).success?
        old_hash = CatalogueDocument.sole.committed_sha256
        assert import(directory, second).success?
        document = CatalogueDocument.sole
        assert_equal "Allowed revision", document.work.title
        assert_equal "changed-work-id", document.work.source_identifier
        assert_equal Digest::SHA256.hexdigest(second), document.committed_sha256
        log = document.import_logs.reorder(:id).last
        assert_equal old_hash, log.previous_committed_sha256
        assert_equal "synthetic-work", log.provenance.fetch("old_work_xml_id")
        assert_equal "changed-work-id", log.provenance.fetch("new_work_xml_id")
      end
    end

    test "competing changed path rejects and cannot claim that path through a failure" do
      in_directory do |owned|
        in_directory do |competing|
          first = official
          assert import(owned, first).success?
          before = domain_snapshot
          assert_equal [1, 0, 1], counts(import(competing, first.sub('Original title', 'Unrecognized revision')))
          assert_equal before, domain_snapshot
          failure = ImportLog.order(:id).last
          assert_equal CatalogueDocument.sole.id, failure.catalogue_document_id
          assert_equal 0, ImportLog.where(status: "success", observed_path: File.realpath(File.join(competing, "record.xml"))).count
          assert import(competing, first).success?, "Original same bytes can subsequently establish successful relocation"
        end
      end
    end

    test "changed key at known path and another document identical bytes at that path never transfer ownership" do
      in_directory do |path_a|
        in_directory do |path_b|
          xml_a = official(key: "A")
          xml_b = official(key: "B", body: '<title>Document B</title>')
          assert import(path_a, xml_a).success?
          assert import(path_b, xml_b).success?
          a = CatalogueDocument.find_by!(record_key: "A")
          b = CatalogueDocument.find_by!(record_key: "B")
          b_attempts = b.import_logs.count
          [xml_a.sub('>A</identifier>', '>unused-key</identifier>'), xml_b].each do |conflict|
            before = domain_snapshot
            assert_equal [1, 0, 1], counts(import(path_a, conflict))
            assert_equal before, domain_snapshot
            failure = ImportLog.order(:id).last
            assert_equal a.id, failure.catalogue_document_id
            assert_equal a.work.id, failure.work_id
          end
          assert_equal "B", ImportLog.order(:id).last.attempted_record_key
          assert_equal b_attempts, b.import_logs.count
          assert_not CatalogueDocument.exists?(record_key: "unused-key")
        end
      end
    end

    test "root and work XML IDs are document scoped and demo has a separate identity namespace" do
      in_directory do |directory|
        File.write(File.join(directory, "a.xml"), official(key: "001"))
        File.write(File.join(directory, "b.xml"), official(key: "1"))
        assert_equal [2, 2, 0], counts(Importer.new(directory: directory).call)
      end
      assert_equal %w[001 1], CatalogueDocument.order(:record_key).pluck(:record_key)
      assert_equal 1, Work.distinct.count(:source_identifier)
      in_directory do |directory|
        assert import(directory, official(key: "001"), input_profile: "demo", fixture_key: "001").success?
      end
      assert_equal 3, CatalogueDocument.count
      assert_equal ["CNW", "demo"], CatalogueDocument.where(record_key: "001").order(:catalogue).pluck(:catalogue)
    end

    test "demo is explicit with stable key and one-work rules while official never falls back" do
      in_directory do |directory|
        xml = official.sub('meiversion="4.0.1"', '').sub(' xmlns="http://www.music-encoding.org/ns/mei"', '')
        assert_equal [1, 0, 1], counts(import(directory, xml))
        assert_equal [1, 0, 1], counts(import(directory, xml, input_profile: "demo"))
        assert import(directory, xml, input_profile: "demo", fixture_key: "explicit-synthetic-key").success?
        assert_equal "demo", CatalogueDocument.sole.input_profile
        assert_nil CatalogueDocument.sole.mei_namespace
        assert_equal "explicit-synthetic-key", CatalogueDocument.sole.record_key
      end
    end

    test "title rank skips blanks preserves unknown types and follows source order without language preference" do
      body = <<~XML
        <title type="main">   </title>
        <title xml:id="first" xml:lang="da">  First\t heading </title>
        <title xml:id="second" xml:lang="en">Second heading</title>
        <title type="uniform">Uniform heading</title>
        <title type="text_source">Searchable source title</title>
        <title type=" main ">Padded unknown type</title>
      XML
      in_directory do |directory|
        assert import(directory, official(body: body)).success?
        work = Work.sole
        assert_equal "First heading", work.title
        assert_equal "untyped/source_order; no language preference", work.display_title_reason
        assert_equal 2, work.display_title_order
        assert_equal [2, 3, 4, 5, 6], work.work_titles.pluck(:source_order)
        assert_equal [nil, nil, "uniform", "text_source", " main "], work.work_titles.pluck(:source_type)
        assert_equal "  First\t heading ", work.work_titles.first.raw_text
        assert_equal "da", work.work_titles.first.source_attributes.fetch("{#{InputDocument::XML_NAMESPACE}}lang")
        assert_equal "/m:mei[1]/m:meiHead[1]/m:workList[1]/m:work[1]/m:title[2]", work.work_titles.first.locator
      end
    end

    test "title alternatives and subordinate fallback are eligible but unknown-only and all-blank fail" do
      { "main" => "main", "  \t" => "untyped", "uniform" => "uniform", "alternative" => "alternative", "subordinate" => "subordinate" }.each_with_index do |(kind, reason), index|
        in_directory do |directory|
          assert import(directory, official(key: "rank-#{index}", body: "<title type=\"#{kind}\">Heading</title>")).success?
          assert_equal "#{reason}/source_order; no language preference", CatalogueDocument.find_by!(record_key: "rank-#{index}").work.display_title_reason
        end
      end
      ['<title type="text_source">Only unknown</title>', '<title>  </title>', '<title type="MAIN">Unknown case</title>'].each do |body|
        in_directory do |directory|
          before = domain_snapshot
          assert_equal [1, 0, 1], counts(import(directory, official(key: "invalid-title", body: body)))
          assert_equal before, domain_snapshot
          assert_equal "No eligible nonblank direct work title", ImportLog.order(:id).last.error_message
        end
      end
    end

    test "classification preserves duplicate terms parent metadata and excludes foreign ownership" do
      body = <<~XML
        <title>Classification probe</title>
        <biblList><bibl><genre>letter</genre><classification><termList><term>Documentary</term></termList></classification></bibl></biblList>
        <classification xml:id="class-a" auth="scheme-a">
          <termList xml:id="list-a" class="#one">
            <term xml:id="term-a" type="category">  Chamber\t music </term>
            <term xml:id="term-b">Chamber music</term><term> </term>
            <termList xml:id="list-inner" auth="nested"><term xml:id="term-c">Nested owned list</term></termList>
            <bibl><term>Foreign bibliography</term></bibl>
            <work><term>Foreign work</term></work>
            <expression><term>Foreign expression</term></expression>
            <classification><term>Foreign nested classification</term></classification>
          </termList>
        </classification>
        <classification auth="scheme-b"><termList><term xml:id="term-d">Second scheme</term></termList></classification>
      XML
      in_directory do |directory|
        assert import(directory, official(body: body)).success?
        work = Work.sole
        terms = work.work_classification_terms.to_a
        assert_equal ["Chamber music", "Chamber music", "Nested owned list", "Second scheme"], terms.map(&:text)
        assert_equal [1, 2, 3, 4], terms.map(&:source_order)
        assert_equal "Chamber music", work.genre
        assert_equal "  Chamber\t music ", terms.first.raw_text
        assert_equal "scheme-a", terms.first.classification_metadata.fetch("attributes").fetch("auth")
        assert_equal ["list-a", "list-inner"], terms[2].term_list_metadata.map { |metadata| metadata.fetch("attributes").fetch("{#{InputDocument::XML_NAMESPACE}}id") }
      end
    end

    test "missing direct classification stays null and does not reuse stale or documentary genre" do
      in_directory do |directory|
        xml = official(body: '<title>Original title</title><classification><term>Music</term></classification>')
        assert import(directory, xml).success?
        changed = official(body: '<title>Original title</title><biblList><bibl><genre>letter</genre></bibl></biblList>')
        assert import(directory, changed).success?
        assert_nil Work.sole.genre
        assert_empty Work.sole.work_classification_terms
      end
    end

    test "injected child persistence failure rolls back all facts and logs one associated safe failure" do
      in_directory do |directory|
        xml = official(body: '<title>Original title</title><movement n="1"><title>Movement</title></movement>')
        assert import(directory, xml).success?
        before = domain_snapshot
        logs_before = ImportLog.count
        changed = xml.sub('Original title', 'Attempted replacement')
        failing_importer = Class.new(Importer) do
          private

          def replace_children(work, extracted)
            super
            raise ActiveRecord::StatementInvalid, "Injected private /absolute/path and XML <data>"
          end
        end
        File.write(File.join(directory, "record.xml"), changed)
        result = failing_importer.new(directory: directory).call
        assert_equal [1, 0, 1], counts(result)
        assert_equal before, domain_snapshot
        assert_equal logs_before + 1, ImportLog.count
        log = ImportLog.order(:id).last
        assert_equal Work.sole.id, log.work_id
        assert_equal CatalogueDocument.sole.id, log.catalogue_document_id
        assert_equal Digest::SHA256.hexdigest(xml), log.previous_committed_sha256
        assert_equal Digest::SHA256.hexdigest(changed), log.attempted_sha256
        assert_equal "Database constraint rejected the imported record", log.error_message
      end
    end

    test "real duplicate child constraint rollback preserves facts and failure can recover deterministically" do
      in_directory do |directory|
        xml = official(body: '<title>Original title</title><movement n="1"><title>Movement</title></movement>')
        fixed_time = Time.utc(2026, 9, 20, 12)
        travel_to(fixed_time) do
          assert import(directory, xml).success?
          document = CatalogueDocument.sole
          work = document.work
          initial_success = work.last_successful_import
          before = domain_snapshot
          invalid = xml.sub('Original title', 'Attempted title').sub('</work>', '<movement n="1"><title>Duplicate</title></movement></work>')
          assert_equal [1, 0, 1], counts(import(directory, invalid))
          assert_equal before, domain_snapshot
          assert_equal "failure", work.reload.latest_import_attempt.status
          assert_equal initial_success.id, work.last_successful_import.id
          assert import(directory, xml).success?
          assert_equal "success", work.reload.latest_import_attempt.status
          assert_equal 3, document.import_logs.count
          assert_equal 1, document.import_logs.where(status: "failure").count
          assert_equal 1, document.import_logs.distinct.count(:imported_at)
        end
      end
    end

    test "malformed known path associates via successful provenance but unknown path stays unassociated" do
      in_directory do |known|
        in_directory do |unknown|
          assert import(known, official).success?
          before = domain_snapshot
          assert_equal [1, 0, 1], counts(import(known, '<mei>'))
          associated = ImportLog.order(:id).last
          assert_equal Work.sole.id, associated.work_id
          assert_equal CatalogueDocument.sole.id, associated.catalogue_document_id
          assert_nil associated.attempted_record_key
          assert_equal before, domain_snapshot
          assert_equal [1, 0, 1], counts(import(unknown, '<mei>'))
          assert_nil ImportLog.order(:id).last.work_id
          assert_nil ImportLog.order(:id).last.catalogue_document_id
          assert_equal before, domain_snapshot
        end
      end
    end

    private

    def official(key: "001", body: '<title>Original title</title>')
      <<~XML
        <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="4.0.1" xml:id="synthetic-document">
          <meiHead><workList><work xml:id="synthetic-work"><identifier label="CNW">#{key}</identifier>
            <contributor><persName role="composer">Synthetic composer</persName></contributor>
            #{body}
          </work></workList></meiHead>
        </mei>
      XML
    end

    def in_directory(&block)
      Dir.mktmpdir("f1-importer-", Rails.root.join("tmp"), &block)
    end

    def import(directory, xml, **options)
      File.write(File.join(directory, "record.xml"), xml)
      Importer.new(directory: directory, **options).call
    end

    def counts(result) = [result.files_seen, result.successes, result.failures]

    def domain_snapshot
      [CatalogueDocument, Work, WorkTitle, WorkClassificationTerm, Composer, CatalogueIdentifier,
        Movement, Instrumentation, SourceReference, Performance, ExternalReference].to_h do |model|
        [model.name, model.order(:id).map(&:attributes)]
      end
    end

    def work_facts(work)
      { "work" => work.attributes, "children" => %i[work_titles work_classification_terms catalogue_identifiers
        movements instrumentations source_references performances external_references].to_h do |association|
          [association, work.public_send(association).reorder(:id).map(&:attributes)]
        end }
    end
  end
end
