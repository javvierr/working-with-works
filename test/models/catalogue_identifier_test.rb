require "test_helper"

class CatalogueIdentifierTest < ActiveSupport::TestCase
  test "accepts the same value under different identifier types for one work" do
    identifier = works(:one).catalogue_identifiers.build(
      identifier_type: "Opus",
      value: catalogue_identifiers(:one).value
    )

    assert identifier.save
  end

  test "rejects an exact repeated type and value for one work" do
    existing = catalogue_identifiers(:one)
    duplicate = existing.work.catalogue_identifiers.build(
      identifier_type: existing.identifier_type,
      value: existing.value
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:value], "has already been taken"
  end

  test "requires an identifier type" do
    identifier = works(:one).catalogue_identifiers.build(value: "Test 1")

    assert_not identifier.valid?
    assert_includes identifier.errors[:identifier_type], "can't be blank"

    identifier.identifier_type = " \t "
    assert_not identifier.valid?
    assert_includes identifier.errors[:identifier_type], "can't be blank"
  end

  test "normalizes incidental identifier type whitespace without changing case" do
    identifier = works(:one).catalogue_identifiers.build(
      identifier_type: "  CnW   Supplement  ",
      value: "Test 2"
    )

    assert identifier.valid?
    assert_equal "CnW Supplement", identifier.identifier_type
  end

  test "database rejects an exact duplicate when model validation is bypassed" do
    existing = catalogue_identifiers(:one)
    now = Time.current

    assert_raises ActiveRecord::RecordNotUnique do
      ActiveRecord::Base.transaction(requires_new: true) do
        CatalogueIdentifier.insert!({
          work_id: existing.work_id,
          identifier_type: existing.identifier_type,
          value: existing.value,
          created_at: now,
          updated_at: now
        })
      end
    end
  end

  test "database schema uses the composite unique identifier invariant" do
    type_column = CatalogueIdentifier.columns_hash.fetch("identifier_type")
    indexes = CatalogueIdentifier.connection.indexes(:catalogue_identifiers)
    composite_index = indexes.find do |index|
      index.columns == %w[work_id identifier_type value]
    end

    assert_not type_column.null
    assert composite_index.unique
    assert_not indexes.any? { |index| index.unique && index.columns == %w[work_id value] }
    assert indexes.any? { |index| index.columns == ["value"] && !index.unique }
    assert indexes.any? { |index| index.columns == ["work_id"] && !index.unique }
  end
end
