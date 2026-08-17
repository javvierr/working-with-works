require "test_helper"

class WorkTest < ActiveSupport::TestCase
  test "requires a title" do
    work = works(:one)
    work.title = nil

    assert_not work.valid?
    assert_includes work.errors[:title], "can't be blank"
  end

  test "requires source traceability" do
    work = works(:one)
    work.source_file = nil

    assert_not work.valid?
    assert_includes work.errors[:source_file], "can't be blank"
  end

  test "exposes catalogue associations" do
    work = works(:one)

    assert_equal "Carl Nielsen", work.composer.name
    assert_equal ["CNW 29"], work.catalogue_identifiers.map(&:value)
    assert_equal ["Allegro"], work.movements.map(&:title)
    assert_includes work.instrumentations.map(&:name), "strings"
    assert_includes work.instrumentations.map(&:name), "4 horns"
  end

  test "catalogue filter resolves bare and prefixed CNW values" do
    work = create_catalogued_work(catalogue_number: "417", identifier_type: "CNW", identifier_value: "417")

    assert_equal [work.id], Work.with_catalogue_number("417").ids
    assert_equal [work.id], Work.with_catalogue_number("CNW 417").ids
    assert_equal [work.id], Work.with_catalogue_number("cnw 417").ids
    assert_equal [work.id], Work.with_catalogue_number("  cNw   417  ").ids
  end

  test "prefixed CNW filter supports labelled fixture values and returns each work once" do
    work = works(:one)
    work.catalogue_identifiers.create!(identifier_type: "CNW", value: "29")

    assert_equal [work.id], Work.with_catalogue_number("CNW 29").ids
  end

  test "prefixed CNW filter does not match another identifier family" do
    work = create_catalogued_work(catalogue_number: "417", identifier_type: "FS", identifier_value: "417")

    assert_not_includes Work.with_catalogue_number("CNW 417").ids, work.id
  end

  test "catalogue filter keeps blank and legacy bare behavior" do
    assert_equal Work.order(:id).ids, Work.with_catalogue_number(nil).order(:id).ids
    assert_equal Work.order(:id).ids, Work.with_catalogue_number("  ").order(:id).ids
    assert_equal [works(:one).id], Work.with_catalogue_number("29").ids
  end

  private

  def create_catalogued_work(catalogue_number:, identifier_type:, identifier_value:)
    work = Work.create!(
      composer: composers(:one),
      title: "Generated catalogue work #{SecureRandom.hex(4)}",
      catalogue_number: catalogue_number,
      source_file: "test/generated/#{SecureRandom.uuid}.xml"
    )
    work.catalogue_identifiers.create!(identifier_type: identifier_type, value: identifier_value)
    work
  end
end
