class AddCatalogueSources < ActiveRecord::Migration[8.1]
  def change
    # A missing mapping is unknown, never an inferred absence of source nodes.
    add_column :catalogue_documents, :source_projection_version, :string
    add_column :catalogue_documents, :source_projection_summary, :jsonb
    add_check_constraint :catalogue_documents, <<~SQL.squish, name: "f2_document_projection_pair"
      COALESCE(
        (source_projection_version IS NULL AND source_projection_summary IS NULL)
        OR (source_projection_version ~ '[^[:space:]]'
            AND jsonb_typeof(source_projection_summary) = 'object'
            AND source_projection_summary->>'state' IN ('absent_in_source', 'complete', 'partial')),
        FALSE)
    SQL

    create_table :source_descriptions do |t|
      t.references :catalogue_document, null: false, foreign_key: true
      node_columns(t)
      %i[identifiers titles classification_terms publication physical_description notes links].each do |field|
        t.jsonb field, null: false, default: []
      end
      t.timestamps
    end
    add_index :source_descriptions, %i[catalogue_document_id xml_id], unique: true, name: "idx_f2_sources_document_xml"
    add_index :source_descriptions, %i[catalogue_document_id source_order], unique: true, name: "idx_f2_sources_document_order"
    add_index :source_descriptions, %i[id catalogue_document_id], unique: true, name: "idx_f2_sources_id_document"
    node_checks(:source_descriptions, "sources")
    array_checks(:source_descriptions, %w[identifiers titles classification_terms publication physical_description notes links], "sources")

    create_table :held_items do |t|
      t.references :catalogue_document, null: false, foreign_key: true
      t.references :source_description, null: false
      node_columns(t)
      %i[identifiers physical_locations physical_description links].each do |field|
        t.jsonb field, null: false, default: []
      end
      t.timestamps
    end
    add_index :held_items, %i[catalogue_document_id xml_id], unique: true, name: "idx_f2_items_document_xml"
    add_index :held_items, %i[source_description_id source_order], unique: true, name: "idx_f2_items_source_order"
    add_foreign_key :held_items, :source_descriptions, column: %i[source_description_id catalogue_document_id],
                    primary_key: %i[id catalogue_document_id], name: "fk_f2_items_source_document"
    node_checks(:held_items, "items")
    array_checks(:held_items, %w[identifiers physical_locations physical_description links], "items")

    create_table :source_relations do |t|
      t.references :catalogue_document, null: false, foreign_key: true
      t.references :source_description, null: false
      t.string :xml_id
      t.text :locator, null: false
      t.integer :relation_order, null: false
      t.integer :token_order, null: false
      t.text :rel
      t.text :raw_target
      t.text :target_token
      t.jsonb :source_attributes, null: false, default: {}
      t.jsonb :parent_metadata, null: false, default: {}
      t.string :resolution_state, null: false
      t.text :resolution_reason
      t.bigint :target_source_description_id
      t.bigint :target_work_id
      t.jsonb :expression_context
      t.timestamps
    end
    add_index :source_relations, %i[source_description_id relation_order token_order], unique: true,
              name: "idx_f2_relations_source_node_token"
    add_index :source_relations, :target_source_description_id
    add_index :source_relations, :target_work_id
    add_foreign_key :source_relations, :source_descriptions, column: %i[source_description_id catalogue_document_id],
                    primary_key: %i[id catalogue_document_id], name: "fk_f2_relations_owner_document"
    add_foreign_key :source_relations, :source_descriptions, column: %i[target_source_description_id catalogue_document_id],
                    primary_key: %i[id catalogue_document_id], on_delete: :restrict, name: "fk_f2_relations_source_target_document"
    add_foreign_key :source_relations, :works, column: %i[target_work_id catalogue_document_id],
                    primary_key: %i[id catalogue_document_id], on_delete: :restrict, name: "fk_f2_relations_work_target_document"
    add_check_constraint :source_relations, "relation_order > 0 AND token_order > 0 AND locator ~ '[^[:space:]]'",
                         name: "f2_relations_required_provenance"
    object_checks(:source_relations, %w[source_attributes parent_metadata], "relations")
    add_check_constraint :source_relations, <<~SQL.squish, name: "f2_relations_typed_resolution"
      COALESCE(
        (resolution_state = 'resolved_expression' AND rel = 'isEmbodimentOf'
         AND target_work_id IS NOT NULL AND target_source_description_id IS NULL AND resolution_reason IS NULL
         AND raw_target ~ '[^[:space:]]' AND target_token = '#' || (expression_context->>'xml_id')
         AND target_token ~ '^#[^#/?[:space:]]+$'
         AND jsonb_typeof(expression_context) = 'object'
         AND jsonb_typeof(expression_context->'xml_id') = 'string' AND expression_context->>'xml_id' ~ '[^[:space:]]'
         AND jsonb_typeof(expression_context->'locator') = 'string' AND expression_context->>'locator' ~ '[^[:space:]]'
         AND jsonb_typeof(expression_context->'attributes') = 'object'
         AND jsonb_typeof(expression_context->'titles') = 'array'
         AND jsonb_typeof(expression_context->'ancestor_expressions') = 'array'
         AND jsonb_typeof(expression_context->'containing_work') = 'object'
         AND jsonb_typeof(expression_context->'containing_work'->'locator') = 'string'
         AND expression_context->'containing_work'->>'locator' ~ '[^[:space:]]')
        OR (resolution_state = 'resolved_source' AND rel IN ('isReproductionOf', 'hasReproduction')
            AND target_source_description_id IS NOT NULL AND target_work_id IS NULL
            AND expression_context IS NULL AND resolution_reason IS NULL
            AND raw_target ~ '[^[:space:]]' AND target_token ~ '^#[^#/?[:space:]]+$')
        OR (resolution_state = 'unresolved' AND target_source_description_id IS NULL AND target_work_id IS NULL
            AND expression_context IS NULL AND resolution_reason ~ '[^[:space:]]'),
        FALSE)
    SQL
  end

  private

  def node_columns(table)
    table.string :xml_id, null: false
    table.text :locator, null: false
    table.integer :source_order, null: false
    table.text :label
    table.string :state, null: false
    %i[source_attributes parent_metadata availability].each { |field| table.jsonb field, null: false, default: {} }
  end

  def node_checks(table, prefix)
    add_check_constraint table, "source_order > 0 AND xml_id ~ '[^[:space:]]' AND locator ~ '[^[:space:]]'",
                         name: "f2_#{prefix}_required_provenance"
    add_check_constraint table, "state IN ('descriptive', 'label_or_link_stub', 'empty_placeholder')",
                         name: "f2_#{prefix}_node_state"
    object_checks(table, %w[source_attributes parent_metadata availability], prefix)
  end

  def object_checks(table, fields, prefix)
    fields.each do |field|
      add_check_constraint table, "jsonb_typeof(#{field}) = 'object'", name: "f2_#{prefix}_#{field}_object"
    end
  end

  def array_checks(table, fields, prefix)
    fields.each do |field|
      add_check_constraint table, "jsonb_typeof(#{field}) = 'array'", name: "f2_#{prefix}_#{field}_array"
    end
  end
end
