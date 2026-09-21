require "test_helper"

class CatalogueFoundationTest < ActiveSupport::TestCase
  test "document identity keeps textual keys and profile namespaces distinct" do
    first = document("27")
    leading_zero = document("027")
    demo = document("27", profile: "demo")
    assert_equal 3, [first.id, leading_zero.id, demo.id].uniq.length

    duplicate = first.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:record_key], "has already been taken"
    assert_raises(ActiveRecord::RecordNotUnique) do
      CatalogueDocument.transaction(requires_new: true) do
        CatalogueDocument.insert_all!([first.attributes.except("id")])
      end
    end
  end

  test "database enforces one work per document while legacy rows remain nullable" do
    first = documented_work("unique")
    assert_nil works(:one).catalogue_document_id
    assert_nil works(:two).catalogue_document_id

    assert_raises(ActiveRecord::RecordNotUnique) do
      Work.transaction(requires_new: true) do
        Work.insert_all!([first.attributes.except("id").merge("source_file" => "test/f1/competing.xml")])
      end
    end
    assert_equal first.id, first.catalogue_document.reload.work.id
  end

  test "typed rows preserve duplicates metadata and source order" do
    work = documented_work("ordered")
    later = work.work_titles.create!(text: "Serenade", raw_text: " Serenade ", source_order: 5,
                                    source_type: "uniform", language: "da", xml_id: "title_later",
                                    locator: "/m:mei/m:meiHead/m:workList/m:work/m:title[5]")
    first = work.work_titles.create!(text: "Serenade", source_order: 1, language: "en", xml_id: "title_first",
                                    locator: "/m:mei/m:meiHead/m:workList/m:work/m:title[1]",
                                    source_attributes: { "{http://www.w3.org/XML/1998/namespace}lang" => "en" })
    assert_equal [first.id, later.id], work.work_titles.reload.map(&:id)
    assert_nil first.source_type
    assert_equal " Serenade ", later.raw_text
    assert_equal "en", first.source_attributes.fetch("{http://www.w3.org/XML/1998/namespace}lang")
    term = work.work_classification_terms.create!(text: "Chamber music", source_order: 1,
                                                locator: "/m:work/m:classification/m:termList/m:term",
                                                term_list_metadata: [{ "attributes" => { "class" => "source-scheme" }, "locator" => "/m:work/m:classification/m:termList" }])
    assert_equal "source-scheme", term.reload.term_list_metadata.first.fetch("attributes").fetch("class")
    invalid = work.work_titles.build(text: "Another title", source_order: 1, locator: "/another")
    assert_not invalid.valid?
  end

  test "all retained titles and terms filter once with literal wildcard handling" do
    work = documented_work("search", title: "Stale scalar heading", genre: "Stale scalar category")
    %w[da en].each_with_index do |language, index|
      work.work_titles.create!(text: "50%_study", source_type: "text_source", language: language,
                              source_order: index + 1, locator: "/title[#{index + 1}]")
      work.work_classification_terms.create!(text: "Chamber_50%", source_order: index + 1,
                                            locator: "/classification/term[#{index + 1}]")
    end
    decoy = documented_work("decoy")
    decoy.work_titles.create!(text: "500xstudy", source_order: 1, locator: "/title[1]")
    decoy.work_classification_terms.create!(text: "Chamberx500", source_order: 1, locator: "/term[1]")

    assert_equal [work.id], Work.search("50%_").ids
    assert_equal [work.id], Work.search("_").ids
    assert_equal [work.id], Work.with_genre("_50%").ids
    assert_equal [work.id], Work.with_genre("%").ids
    assert_not_includes Work.search("Stale scalar heading").ids, work.id
    assert_not_includes Work.with_genre("Stale scalar category").ids, work.id
    assert_includes Work.search("Carl Nielsen").ids, work.id
    assert_equal [work.id], Work.search("CNW F1-search").ids
    assert_equal [works(:one).id], Work.search("Inextinguishable").ids
    assert_equal [works(:one).id], Work.with_genre("Symphony").ids
  end

  test "a validated document with no classifications does not use a stale genre" do
    work = documented_work("missing", genre: "Unsupported stale category")
    assert_empty work.work_classification_terms
    assert_not_includes Work.with_genre("Unsupported stale category").ids, work.id
  end

  test "attempt history distinguishes failure and successful version with deterministic ties" do
    work = documented_work("history")
    at = Time.utc(2026, 9, 19, 12)
    success = work.import_logs.create!(catalogue_document: work.catalogue_document, source_file: work.source_file,
                                      status: "success", imported_at: at)
    failure = work.import_logs.create!(catalogue_document: work.catalogue_document, source_file: work.source_file,
                                      status: "failure", imported_at: at, error_message: "Controlled validation failure")
    assert_equal failure.id, work.latest_import_attempt.id
    assert_equal success.id, work.last_successful_import.id
    work.catalogue_document.import_logs.load
    assert_equal failure.id, work.latest_import_attempt.id
    assert_equal success.id, work.last_successful_import.id

    legacy = works(:one)
    legacy_failure = legacy.import_logs.create!(source_file: legacy.source_file, status: "failure", imported_at: at)
    assert_equal legacy_failure.id, legacy.latest_import_attempt.id
    assert_nil legacy.last_successful_import
  end

  test "an attempt cannot link another documents work even when validations are bypassed" do
    first = documented_work("ownership-a")
    second = documented_work("ownership-b")
    attributes = { work_id: first.id, catalogue_document_id: second.catalogue_document_id,
                   source_file: "test/f1/conflict.xml", status: "failure", imported_at: Time.current }
    log = ImportLog.new(attributes)
    assert_not log.valid?
    assert_raises(ActiveRecord::InvalidForeignKey) do
      ImportLog.transaction(requires_new: true) { ImportLog.insert_all!([attributes]) }
    end
  end

  test "public diagnostics are bounded and omit paths payloads and following trace lines" do
    log = ImportLog.new(error_message: "Invalid input at /private/tmp/f1-secret.xml\nfrom /Users/person/private.rb:12",
                        warnings: ["Review https://user:secret@example.invalid/private", "<mei>private payload</mei>"])
    assert_not_includes log.safe_error_message, "/private/"
    assert_not_includes log.safe_error_message, "private.rb"
    assert_not_includes log.safe_warnings.join(" "), "secret"
    assert_not_includes log.safe_warnings.join(" "), "private payload"
    log.error_message = "a" * 700
    assert_operator log.safe_error_message.length, :<=, 512
  end

  private

  def document(key, profile: "official_cnw_v401")
    CatalogueDocument.create!(input_profile: profile, catalogue: profile == "demo" ? "demo" : "CNW",
                              record_key: key, raw_record_identifier: key, committed_sha256: "a" * 64,
                              root_xml_id: "shared_document_local_id")
  end

  def documented_work(key, title: "Generated heading", genre: nil)
    Work.create!(catalogue_document: document(key), composer: composers(:one), title: title,
                 genre: genre, source_file: "test/f1/#{key}.xml", source_identifier: "shared_work_local_id",
                 catalogue_number: "CNW F1-#{key}", display_title_reason: "untyped", display_title_order: 1)
  end
end
