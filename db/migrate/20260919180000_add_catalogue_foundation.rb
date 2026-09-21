class AddCatalogueFoundation < ActiveRecord::Migration[8.1]
  def change
    create_table :catalogue_documents do |t|
      t.string :input_profile, null: false
      t.string :catalogue, null: false
      t.string :record_key, null: false
      t.text :raw_record_identifier
      t.jsonb :identifier_attributes, null: false, default: {}
      t.string :root_xml_id
      t.string :mei_namespace
      t.string :mei_version
      t.string :committed_sha256, null: false
      t.string :origin_relative_name
      t.text :latest_successful_path
      t.datetime :last_successful_at
      t.timestamps
    end
    add_index :catalogue_documents, %i[input_profile catalogue record_key], unique: true,
              name: "index_catalogue_documents_on_logical_identity"
    add_check_constraint :catalogue_documents, "input_profile IN ('official_cnw_v401', 'demo')",
                         name: "catalogue_documents_supported_profile"
    add_check_constraint :catalogue_documents, "committed_sha256 ~ '^[0-9a-f]{64}$'",
                         name: "catalogue_documents_committed_sha256"
    add_check_constraint :catalogue_documents, "jsonb_typeof(identifier_attributes) = 'object'",
                         name: "catalogue_documents_identifier_attributes_object"

    # Existing rows remain explicitly unvalidated: no inferred identity backfill.
    add_reference :works, :catalogue_document, null: true, foreign_key: true, index: { unique: true }
    add_column :works, :display_title_reason, :string
    add_column :works, :display_title_order, :integer
    add_check_constraint :works, "display_title_order IS NULL OR display_title_order > 0",
                         name: "works_positive_display_title_order"
    add_index :works, %i[id catalogue_document_id], unique: true,
              name: "index_works_on_id_and_catalogue_document"

    create_table :work_titles do |t|
      t.references :work, null: false, foreign_key: true
      t.text :text, null: false
      t.text :raw_text
      t.string :source_type
      t.string :language
      t.string :xml_id
      t.integer :source_order, null: false
      t.text :locator, null: false
      t.jsonb :source_attributes, null: false, default: {}
      t.timestamps
    end
    add_index :work_titles, %i[work_id source_order], unique: true
    add_index :work_titles, %i[work_id xml_id], unique: true, where: "xml_id IS NOT NULL"
    add_check_constraint :work_titles, "source_order > 0", name: "work_titles_positive_source_order"
    add_check_constraint :work_titles, "jsonb_typeof(source_attributes) = 'object'",
                         name: "work_titles_source_attributes_object"

    create_table :work_classification_terms do |t|
      t.references :work, null: false, foreign_key: true
      t.text :text, null: false
      t.text :raw_text
      t.string :xml_id
      t.integer :source_order, null: false
      t.text :locator, null: false
      t.jsonb :source_attributes, null: false, default: {}
      t.jsonb :classification_metadata, null: false, default: {}
      t.jsonb :term_list_metadata, null: false, default: []
      t.timestamps
    end
    add_index :work_classification_terms, %i[work_id source_order], unique: true,
              name: "index_work_terms_on_work_and_order"
    add_index :work_classification_terms, %i[work_id xml_id], unique: true,
              where: "xml_id IS NOT NULL", name: "index_work_terms_on_work_and_xml_id"
    add_check_constraint :work_classification_terms, "source_order > 0", name: "work_terms_positive_source_order"
    add_check_constraint :work_classification_terms, "jsonb_typeof(source_attributes) = 'object'",
                         name: "work_terms_source_attributes_object"
    add_check_constraint :work_classification_terms, "jsonb_typeof(classification_metadata) = 'object'",
                         name: "work_terms_classification_metadata_object"
    add_check_constraint :work_classification_terms, "jsonb_typeof(term_list_metadata) = 'array'",
                         name: "work_terms_term_list_metadata_array"

    add_reference :import_logs, :catalogue_document, null: true, foreign_key: true, index: false
    add_column :import_logs, :attempted_profile, :string
    add_column :import_logs, :attempted_catalogue, :string
    add_column :import_logs, :attempted_record_key, :string
    add_column :import_logs, :attempted_sha256, :string
    add_column :import_logs, :previous_committed_sha256, :string
    add_column :import_logs, :observed_path, :text
    add_column :import_logs, :provenance, :jsonb, null: false, default: {}
    add_index :import_logs, %i[catalogue_document_id imported_at id], name: "index_import_logs_on_document_attempt_order"
    add_index :import_logs, %i[observed_path status], name: "index_import_logs_on_observed_path_and_status"
    add_check_constraint :import_logs, "jsonb_typeof(provenance) = 'object'", name: "import_logs_provenance_object"
    # Both links may be absent on legacy/unknown failures. When both are present,
    # they must describe the same document/work rather than two unrelated rows.
    add_foreign_key :import_logs, :works, column: %i[work_id catalogue_document_id],
                    primary_key: %i[id catalogue_document_id], name: "fk_import_logs_work_document"
  end
end
