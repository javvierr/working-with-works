require "test_helper"

class CatalogueSourcesTest < ActiveSupport::TestCase
  test "legacy projection stays unknown and an older marker can be upgraded" do
    record = document("marker")
    assert_nil record.source_projection_version
    assert_nil record.source_projection_summary
    assert_empty record.source_descriptions
    record.update!(source_projection_version: "cnw_sources_v0", source_projection_summary: { state: "partial" })
    assert_equal "cnw_sources_v0", record.reload.source_projection_version

    assert_database_update_rejected(record, source_projection_version: nil)
    assert_database_update_rejected(record, source_projection_summary: nil)
    assert_database_update_rejected(record, source_projection_summary: {})
    assert_database_update_rejected(record, source_projection_summary: { state: "not_projected" })
    assert_database_update_rejected(record, source_projection_summary: [])
    assert_equal({ "state" => "partial" }, record.source_projection_summary)
  end

  test "source descriptions are document owned and ordered without requiring a work" do
    record = document("document-only")
    later = source(record, "source-later", order: 4)
    first = source(record, "source-first", order: 1)
    assert_nil record.work
    assert_equal [first.id, later.id], record.source_descriptions.reload.map(&:id)
    same_xml_in_other_document = source(document("other-document"), first.xml_id)
    assert_not_equal first.id, same_xml_in_other_document.id

    assert_database_insert_rejected(SourceDescription, row(first).merge("source_order" => 5), ActiveRecord::RecordNotUnique)
    assert_database_insert_rejected(SourceDescription, row(first).merge("xml_id" => "another-id"), ActiveRecord::RecordNotUnique)
  end

  test "items retain their ordered parent and document local identity" do
    record = document("items")
    first_source = source(record, "first")
    second_source = source(record, "second", order: 2)
    later = item(first_source, "item-later", order: 3)
    first = item(first_source, "item-first", order: 1)
    assert_equal [first.id, later.id], first_source.held_items.reload.map(&:id)
    foreign_source = source(document("foreign-items"), "first")
    assert_not_equal first.id, item(foreign_source, "item-first").id

    # Use the other local item so the foreign document has no colliding XML ID.
    invalid = HeldItem.new(row(later).merge("catalogue_document_id" => foreign_source.catalogue_document_id))
    assert_not invalid.valid?
    assert_database_update_rejected(later, { catalogue_document_id: foreign_source.catalogue_document_id }, ActiveRecord::InvalidForeignKey)
    assert_database_insert_rejected(HeldItem, row(first).merge("source_description_id" => second_source.id), ActiveRecord::RecordNotUnique)
    assert_database_insert_rejected(HeldItem, row(first).merge("xml_id" => "distinct-id"), ActiveRecord::RecordNotUnique)
  end

  test "required provenance and selected JSON shapes survive bypassed validation" do
    description = source(document("required"), "source")
    held = item(description, "item")
    [description, held].each do |record|
      assert_database_update_rejected(record, { catalogue_document_id: nil }, ActiveRecord::NotNullViolation)
      assert_database_update_rejected(record, { xml_id: nil }, ActiveRecord::NotNullViolation)
      assert_database_update_rejected(record, xml_id: "")
      assert_database_update_rejected(record, locator: " ")
      assert_database_update_rejected(record, source_order: 0)
      assert_database_update_rejected(record, state: "asserted_copy")
      assert_database_update_rejected(record, source_attributes: [])
      assert_database_update_rejected(record, parent_metadata: [])
      assert_database_update_rejected(record, availability: [])
    end
    assert_database_update_rejected(description, titles: {})
    assert_database_update_rejected(description, classification_terms: {})
    assert_database_update_rejected(held, physical_locations: {})
    assert_database_update_rejected(held, identifiers: {})
  end

  test "selected blank and duplicate values remain distinct with their raw metadata" do
    blank = { "text" => nil, "raw_text" => " \n ", "source_order" => 1,
              "attributes" => { "type" => "unknown", "{http://www.w3.org/XML/1998/namespace}lang" => "da" } }
    duplicate_a = { "text" => "Score", "raw_text" => " Score ", "source_order" => 2 }
    duplicate_b = { "text" => "Score", "raw_text" => "Score", "source_order" => 3 }
    description = source(document("values"), "source")
    description.update!(titles: [blank, duplicate_a, duplicate_b], state: "descriptive")
    assert_equal [blank, duplicate_a, duplicate_b], description.reload.titles
    assert_equal "descriptive", description.state
    assert_empty description.held_items
  end

  test "relations enforce owner and source target document even without model validation" do
    record = document("relations")
    owner = source(record, "owner")
    target = source(record, "target", order: 2)
    foreign_target = source(document("foreign-relations"), "target")
    relation = source_link(owner, target)
    assert_equal target.id, relation.target_source_description.id
    assert_database_update_rejected(relation, { catalogue_document_id: foreign_target.catalogue_document_id }, ActiveRecord::InvalidForeignKey)
    assert_database_update_rejected(relation, { target_source_description_id: foreign_target.id }, ActiveRecord::InvalidForeignKey)

    invalid = relation.dup
    invalid.target_source_description = foreign_target
    assert_not invalid.valid?
    assert_includes invalid.errors[:target_source_description], "must belong to this catalogue document"
  end

  test "expression context has one typed same document work target" do
    record = document("expression")
    owner = source(record, "source")
    work = owned_work(record)
    other_work = owned_work(document("foreign-expression"))
    relation = owner.source_relations.create!(catalogue_document: record, locator: "/relation[1]",
      relation_order: 1, token_order: 1, rel: "isEmbodimentOf", raw_target: "#expression-child",
      target_token: "#expression-child", resolution_state: "resolved_expression", target_work: work,
      expression_context: expression_context)
    assert_equal work.id, relation.target_work.id
    assert_equal ["expression-parent"], relation.expression_context.fetch("ancestor_expressions").map { |row| row.fetch("xml_id") }
    assert_database_update_rejected(relation, { target_work_id: other_work.id }, ActiveRecord::InvalidForeignKey)
    assert_database_update_rejected(relation, target_source_description_id: owner.id)
    assert_database_update_rejected(relation, target_work_id: nil)
    assert_database_update_rejected(relation, expression_context: nil)
    assert_database_update_rejected(relation, expression_context: {})
    assert_database_update_rejected(relation, expression_context: expression_context.except("xml_id"))
    assert_database_update_rejected(relation, target_token: "#different-expression")
  end

  test "unresolved records and repeated relation node IDs retain every token with consistent state" do
    record = document("tokens")
    owner = source(record, "source")
    common = { catalogue_document: record, xml_id: "one-relation-node", locator: "/relation[1]",
               relation_order: 1, rel: "isEmbodimentOf", raw_target: "#missing-a #missing-b",
               resolution_state: "unresolved", resolution_reason: "missing_fragment" }
    second = owner.source_relations.create!(common.merge(token_order: 2, target_token: "#missing-b"))
    first = owner.source_relations.create!(common.merge(token_order: 1, target_token: "#missing-a"))
    assert_equal [first.id, second.id], owner.source_relations.reload.map(&:id)
    assert_equal ["one-relation-node", "one-relation-node"], owner.source_relations.map(&:xml_id)
    assert_database_insert_rejected(SourceRelation, row(first), ActiveRecord::RecordNotUnique)
    assert_database_update_rejected(first, token_order: 0)
    assert_database_update_rejected(first, relation_order: 0)
    assert_database_update_rejected(first, resolution_reason: nil)
    assert_database_update_rejected(first, resolution_state: "resolved_source")
    assert_database_update_rejected(first, target_source_description_id: owner.id)
    assert_database_update_rejected(first, expression_context: {})
  end

  test "document destruction clears cyclic edges before targets and keeps another document" do
    record = document("cycle")
    first = source(record, "a")
    second = source(record, "b", order: 2)
    item(first, "a-copy")
    source_link(first, second)
    source_link(second, first)
    source_link(first, first, order: 2)
    other = source(document("survivor"), "a")
    assert_database_delete_rejected(second)
    record.destroy!
    assert_not SourceDescription.exists?(id: [first.id, second.id])
    assert_not SourceRelation.exists?(catalogue_document_id: record.id)
    assert_not HeldItem.exists?(catalogue_document_id: record.id)
    assert SourceDescription.exists?(id: other.id)
  end

  private

  def document(key)
    CatalogueDocument.create!(input_profile: "official_cnw_v401", catalogue: "CNW", record_key: "F2-#{key}",
                              raw_record_identifier: "F2-#{key}", committed_sha256: "b" * 64)
  end

  def source(record, xml_id, order: 1)
    record.source_descriptions.create!(xml_id: xml_id, locator: "/source[#{order}]", source_order: order,
                                       state: "empty_placeholder")
  end

  def item(description, xml_id, order: 1)
    description.held_items.create!(catalogue_document: description.catalogue_document, xml_id: xml_id,
                                   locator: "/source/item[#{order}]", source_order: order, state: "empty_placeholder")
  end

  def source_link(owner, target, order: 1)
    owner.source_relations.create!(catalogue_document: owner.catalogue_document, locator: "/relation[#{order}]",
      relation_order: order, token_order: 1, rel: "isReproductionOf", raw_target: "##{target.xml_id}",
      target_token: "##{target.xml_id}", resolution_state: "resolved_source", target_source_description: target)
  end

  def owned_work(record)
    Work.create!(catalogue_document: record, composer: composers(:one), title: "Generated F2 work",
                 source_file: "test/f2/#{record.record_key}.xml", source_identifier: "work-local")
  end

  def expression_context
    { "xml_id" => "expression-child", "locator" => "/work/expression/expression", "label" => nil,
      "attributes" => {}, "titles" => [], "ancestor_expressions" => [
        { "xml_id" => "expression-parent", "locator" => "/work/expression", "label" => nil,
          "attributes" => {}, "titles" => [] }
      ], "containing_work" => { "xml_id" => "work-local", "locator" => "/work" } }
  end

  def row(record)
    record.attributes.except("id", "created_at", "updated_at")
  end

  def assert_database_update_rejected(record, attributes, error_class = ActiveRecord::StatementInvalid)
    assert_raises(error_class) do
      record.class.transaction(requires_new: true) { record.update_columns(attributes) }
    end
    record.reload
  end

  def assert_database_insert_rejected(model, attributes, error_class)
    assert_raises(error_class) do
      model.transaction(requires_new: true) { model.insert_all!([attributes]) }
    end
  end

  def assert_database_delete_rejected(record)
    assert_raises(ActiveRecord::InvalidForeignKey) do
      record.class.transaction(requires_new: true) { record.delete }
    end
    record.reload
  end
end
