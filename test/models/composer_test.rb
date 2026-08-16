require "test_helper"

class ComposerTest < ActiveSupport::TestCase
  test "requires a name" do
    composer = Composer.new

    assert_not composer.valid?
    assert_includes composer.errors[:name], "can't be blank"
  end

  test "requires a unique name" do
    composer = Composer.new(name: composers(:one).name)

    assert_not composer.valid?
    assert_includes composer.errors[:name], "has already been taken"
  end

  test "has works" do
    assert_includes composers(:one).works, works(:one)
  end
end
