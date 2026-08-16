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
end
