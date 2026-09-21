# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_19_233000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "catalogue_documents", force: :cascade do |t|
    t.string "catalogue", null: false
    t.string "committed_sha256", null: false
    t.datetime "created_at", null: false
    t.jsonb "identifier_attributes", default: {}, null: false
    t.string "input_profile", null: false
    t.datetime "last_successful_at"
    t.text "latest_successful_path"
    t.string "mei_namespace"
    t.string "mei_version"
    t.string "origin_relative_name"
    t.text "raw_record_identifier"
    t.string "record_key", null: false
    t.string "root_xml_id"
    t.jsonb "source_projection_summary"
    t.string "source_projection_version"
    t.datetime "updated_at", null: false
    t.index ["input_profile", "catalogue", "record_key"], name: "index_catalogue_documents_on_logical_identity", unique: true
    t.check_constraint "COALESCE(source_projection_version IS NULL AND source_projection_summary IS NULL OR source_projection_version::text ~ '[^[:space:]]'::text AND jsonb_typeof(source_projection_summary) = 'object'::text AND ((source_projection_summary ->> 'state'::text) = ANY (ARRAY['absent_in_source'::text, 'complete'::text, 'partial'::text])), false)", name: "f2_document_projection_pair"
    t.check_constraint "committed_sha256::text ~ '^[0-9a-f]{64}$'::text", name: "catalogue_documents_committed_sha256"
    t.check_constraint "input_profile::text = ANY (ARRAY['official_cnw_v401'::character varying::text, 'demo'::character varying::text])", name: "catalogue_documents_supported_profile"
    t.check_constraint "jsonb_typeof(identifier_attributes) = 'object'::text", name: "catalogue_documents_identifier_attributes_object"
  end

  create_table "catalogue_identifiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "identifier_type", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.bigint "work_id", null: false
    t.index ["value"], name: "index_catalogue_identifiers_on_value"
    t.index ["work_id", "identifier_type", "value"], name: "index_catalogue_identifiers_on_work_type_value", unique: true
    t.index ["work_id"], name: "index_catalogue_identifiers_on_work_id"
  end

  create_table "composers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_composers_on_name", unique: true
  end

  create_table "external_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "work_id", null: false
    t.index ["url"], name: "index_external_references_on_url"
    t.index ["work_id"], name: "index_external_references_on_work_id"
  end

  create_table "held_items", force: :cascade do |t|
    t.jsonb "availability", default: {}, null: false
    t.bigint "catalogue_document_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "identifiers", default: [], null: false
    t.text "label"
    t.jsonb "links", default: [], null: false
    t.text "locator", null: false
    t.jsonb "parent_metadata", default: {}, null: false
    t.jsonb "physical_description", default: [], null: false
    t.jsonb "physical_locations", default: [], null: false
    t.jsonb "source_attributes", default: {}, null: false
    t.bigint "source_description_id", null: false
    t.integer "source_order", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.string "xml_id", null: false
    t.index ["catalogue_document_id", "xml_id"], name: "idx_f2_items_document_xml", unique: true
    t.index ["catalogue_document_id"], name: "index_held_items_on_catalogue_document_id"
    t.index ["source_description_id", "source_order"], name: "idx_f2_items_source_order", unique: true
    t.index ["source_description_id"], name: "index_held_items_on_source_description_id"
    t.check_constraint "jsonb_typeof(availability) = 'object'::text", name: "f2_items_availability_object"
    t.check_constraint "jsonb_typeof(identifiers) = 'array'::text", name: "f2_items_identifiers_array"
    t.check_constraint "jsonb_typeof(links) = 'array'::text", name: "f2_items_links_array"
    t.check_constraint "jsonb_typeof(parent_metadata) = 'object'::text", name: "f2_items_parent_metadata_object"
    t.check_constraint "jsonb_typeof(physical_description) = 'array'::text", name: "f2_items_physical_description_array"
    t.check_constraint "jsonb_typeof(physical_locations) = 'array'::text", name: "f2_items_physical_locations_array"
    t.check_constraint "jsonb_typeof(source_attributes) = 'object'::text", name: "f2_items_source_attributes_object"
    t.check_constraint "source_order > 0 AND xml_id::text ~ '[^[:space:]]'::text AND locator ~ '[^[:space:]]'::text", name: "f2_items_required_provenance"
    t.check_constraint "state::text = ANY (ARRAY['descriptive'::character varying, 'label_or_link_stub'::character varying, 'empty_placeholder'::character varying]::text[])", name: "f2_items_node_state"
  end

  create_table "import_logs", force: :cascade do |t|
    t.string "attempted_catalogue"
    t.string "attempted_profile"
    t.string "attempted_record_key"
    t.string "attempted_sha256"
    t.bigint "catalogue_document_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "imported_at", null: false
    t.text "observed_path"
    t.string "previous_committed_sha256"
    t.jsonb "provenance", default: {}, null: false
    t.string "source_file", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.jsonb "warnings", default: [], null: false
    t.bigint "work_id"
    t.string "work_title"
    t.index ["catalogue_document_id", "imported_at", "id"], name: "index_import_logs_on_document_attempt_order"
    t.index ["imported_at"], name: "index_import_logs_on_imported_at"
    t.index ["observed_path", "status"], name: "index_import_logs_on_observed_path_and_status"
    t.index ["source_file"], name: "index_import_logs_on_source_file"
    t.index ["status"], name: "index_import_logs_on_status"
    t.index ["work_id"], name: "index_import_logs_on_work_id"
    t.check_constraint "jsonb_typeof(provenance) = 'object'::text", name: "import_logs_provenance_object"
  end

  create_table "instrumentations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "section"
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.index ["name"], name: "index_instrumentations_on_name"
    t.index ["work_id", "name"], name: "index_instrumentations_on_work_id_and_name", unique: true
    t.index ["work_id"], name: "index_instrumentations_on_work_id"
  end

  create_table "movements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "duration"
    t.integer "position"
    t.string "tempo_marking"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.index ["work_id", "position"], name: "index_movements_on_work_id_and_position", unique: true
    t.index ["work_id"], name: "index_movements_on_work_id"
  end

  create_table "performances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.text "note"
    t.date "performed_on"
    t.text "performers"
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.index ["location"], name: "index_performances_on_location"
    t.index ["performed_on"], name: "index_performances_on_performed_on"
    t.index ["work_id"], name: "index_performances_on_work_id"
  end

  create_table "source_descriptions", force: :cascade do |t|
    t.jsonb "availability", default: {}, null: false
    t.bigint "catalogue_document_id", null: false
    t.jsonb "classification_terms", default: [], null: false
    t.datetime "created_at", null: false
    t.jsonb "identifiers", default: [], null: false
    t.text "label"
    t.jsonb "links", default: [], null: false
    t.text "locator", null: false
    t.jsonb "notes", default: [], null: false
    t.jsonb "parent_metadata", default: {}, null: false
    t.jsonb "physical_description", default: [], null: false
    t.jsonb "publication", default: [], null: false
    t.jsonb "source_attributes", default: {}, null: false
    t.integer "source_order", null: false
    t.string "state", null: false
    t.jsonb "titles", default: [], null: false
    t.datetime "updated_at", null: false
    t.string "xml_id", null: false
    t.index ["catalogue_document_id", "source_order"], name: "idx_f2_sources_document_order", unique: true
    t.index ["catalogue_document_id", "xml_id"], name: "idx_f2_sources_document_xml", unique: true
    t.index ["catalogue_document_id"], name: "index_source_descriptions_on_catalogue_document_id"
    t.index ["id", "catalogue_document_id"], name: "idx_f2_sources_id_document", unique: true
    t.check_constraint "jsonb_typeof(availability) = 'object'::text", name: "f2_sources_availability_object"
    t.check_constraint "jsonb_typeof(classification_terms) = 'array'::text", name: "f2_sources_classification_terms_array"
    t.check_constraint "jsonb_typeof(identifiers) = 'array'::text", name: "f2_sources_identifiers_array"
    t.check_constraint "jsonb_typeof(links) = 'array'::text", name: "f2_sources_links_array"
    t.check_constraint "jsonb_typeof(notes) = 'array'::text", name: "f2_sources_notes_array"
    t.check_constraint "jsonb_typeof(parent_metadata) = 'object'::text", name: "f2_sources_parent_metadata_object"
    t.check_constraint "jsonb_typeof(physical_description) = 'array'::text", name: "f2_sources_physical_description_array"
    t.check_constraint "jsonb_typeof(publication) = 'array'::text", name: "f2_sources_publication_array"
    t.check_constraint "jsonb_typeof(source_attributes) = 'object'::text", name: "f2_sources_source_attributes_object"
    t.check_constraint "jsonb_typeof(titles) = 'array'::text", name: "f2_sources_titles_array"
    t.check_constraint "source_order > 0 AND xml_id::text ~ '[^[:space:]]'::text AND locator ~ '[^[:space:]]'::text", name: "f2_sources_required_provenance"
    t.check_constraint "state::text = ANY (ARRAY['descriptive'::character varying, 'label_or_link_stub'::character varying, 'empty_placeholder'::character varying]::text[])", name: "f2_sources_node_state"
  end

  create_table "source_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "label"
    t.string "repository"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.index ["source_type"], name: "index_source_references_on_source_type"
    t.index ["work_id"], name: "index_source_references_on_work_id"
  end

  create_table "source_relations", force: :cascade do |t|
    t.bigint "catalogue_document_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "expression_context"
    t.text "locator", null: false
    t.jsonb "parent_metadata", default: {}, null: false
    t.text "raw_target"
    t.text "rel"
    t.integer "relation_order", null: false
    t.text "resolution_reason"
    t.string "resolution_state", null: false
    t.jsonb "source_attributes", default: {}, null: false
    t.bigint "source_description_id", null: false
    t.bigint "target_source_description_id"
    t.text "target_token"
    t.bigint "target_work_id"
    t.integer "token_order", null: false
    t.datetime "updated_at", null: false
    t.string "xml_id"
    t.index ["catalogue_document_id"], name: "index_source_relations_on_catalogue_document_id"
    t.index ["source_description_id", "relation_order", "token_order"], name: "idx_f2_relations_source_node_token", unique: true
    t.index ["source_description_id"], name: "index_source_relations_on_source_description_id"
    t.index ["target_source_description_id"], name: "index_source_relations_on_target_source_description_id"
    t.index ["target_work_id"], name: "index_source_relations_on_target_work_id"
    t.check_constraint "COALESCE(resolution_state::text = 'resolved_expression'::text AND rel = 'isEmbodimentOf'::text AND target_work_id IS NOT NULL AND target_source_description_id IS NULL AND resolution_reason IS NULL AND raw_target ~ '[^[:space:]]'::text AND target_token = ('#'::text || (expression_context ->> 'xml_id'::text)) AND target_token ~ '^#[^#/?[:space:]]+$'::text AND jsonb_typeof(expression_context) = 'object'::text AND jsonb_typeof(expression_context -> 'xml_id'::text) = 'string'::text AND (expression_context ->> 'xml_id'::text) ~ '[^[:space:]]'::text AND jsonb_typeof(expression_context -> 'locator'::text) = 'string'::text AND (expression_context ->> 'locator'::text) ~ '[^[:space:]]'::text AND jsonb_typeof(expression_context -> 'attributes'::text) = 'object'::text AND jsonb_typeof(expression_context -> 'titles'::text) = 'array'::text AND jsonb_typeof(expression_context -> 'ancestor_expressions'::text) = 'array'::text AND jsonb_typeof(expression_context -> 'containing_work'::text) = 'object'::text AND jsonb_typeof((expression_context -> 'containing_work'::text) -> 'locator'::text) = 'string'::text AND ((expression_context -> 'containing_work'::text) ->> 'locator'::text) ~ '[^[:space:]]'::text OR resolution_state::text = 'resolved_source'::text AND (rel = ANY (ARRAY['isReproductionOf'::text, 'hasReproduction'::text])) AND target_source_description_id IS NOT NULL AND target_work_id IS NULL AND expression_context IS NULL AND resolution_reason IS NULL AND raw_target ~ '[^[:space:]]'::text AND target_token ~ '^#[^#/?[:space:]]+$'::text OR resolution_state::text = 'unresolved'::text AND target_source_description_id IS NULL AND target_work_id IS NULL AND expression_context IS NULL AND resolution_reason ~ '[^[:space:]]'::text, false)", name: "f2_relations_typed_resolution"
    t.check_constraint "jsonb_typeof(parent_metadata) = 'object'::text", name: "f2_relations_parent_metadata_object"
    t.check_constraint "jsonb_typeof(source_attributes) = 'object'::text", name: "f2_relations_source_attributes_object"
    t.check_constraint "relation_order > 0 AND token_order > 0 AND locator ~ '[^[:space:]]'::text", name: "f2_relations_required_provenance"
  end

  create_table "work_classification_terms", force: :cascade do |t|
    t.jsonb "classification_metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "locator", null: false
    t.text "raw_text"
    t.jsonb "source_attributes", default: {}, null: false
    t.integer "source_order", null: false
    t.jsonb "term_list_metadata", default: [], null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.string "xml_id"
    t.index ["work_id", "source_order"], name: "index_work_terms_on_work_and_order", unique: true
    t.index ["work_id", "xml_id"], name: "index_work_terms_on_work_and_xml_id", unique: true, where: "(xml_id IS NOT NULL)"
    t.index ["work_id"], name: "index_work_classification_terms_on_work_id"
    t.check_constraint "jsonb_typeof(classification_metadata) = 'object'::text", name: "work_terms_classification_metadata_object"
    t.check_constraint "jsonb_typeof(source_attributes) = 'object'::text", name: "work_terms_source_attributes_object"
    t.check_constraint "jsonb_typeof(term_list_metadata) = 'array'::text", name: "work_terms_term_list_metadata_array"
    t.check_constraint "source_order > 0", name: "work_terms_positive_source_order"
  end

  create_table "work_titles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "language"
    t.text "locator", null: false
    t.text "raw_text"
    t.jsonb "source_attributes", default: {}, null: false
    t.integer "source_order", null: false
    t.string "source_type"
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.bigint "work_id", null: false
    t.string "xml_id"
    t.index ["work_id", "source_order"], name: "index_work_titles_on_work_id_and_source_order", unique: true
    t.index ["work_id", "xml_id"], name: "index_work_titles_on_work_id_and_xml_id", unique: true, where: "(xml_id IS NOT NULL)"
    t.index ["work_id"], name: "index_work_titles_on_work_id"
    t.check_constraint "jsonb_typeof(source_attributes) = 'object'::text", name: "work_titles_source_attributes_object"
    t.check_constraint "source_order > 0", name: "work_titles_positive_source_order"
  end

  create_table "works", force: :cascade do |t|
    t.bigint "catalogue_document_id"
    t.string "catalogue_number"
    t.bigint "composer_id", null: false
    t.string "composition_date"
    t.integer "composition_year"
    t.datetime "created_at", null: false
    t.integer "display_title_order"
    t.string "display_title_reason"
    t.string "genre"
    t.string "source_file", null: false
    t.string "source_identifier"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_document_id"], name: "index_works_on_catalogue_document_id", unique: true
    t.index ["catalogue_number"], name: "index_works_on_catalogue_number"
    t.index ["composer_id"], name: "index_works_on_composer_id"
    t.index ["composition_year"], name: "index_works_on_composition_year"
    t.index ["genre"], name: "index_works_on_genre"
    t.index ["id", "catalogue_document_id"], name: "index_works_on_id_and_catalogue_document", unique: true
    t.index ["source_file"], name: "index_works_on_source_file", unique: true
    t.index ["title"], name: "index_works_on_title"
    t.check_constraint "display_title_order IS NULL OR display_title_order > 0", name: "works_positive_display_title_order"
  end

  add_foreign_key "catalogue_identifiers", "works"
  add_foreign_key "external_references", "works"
  add_foreign_key "held_items", "catalogue_documents"
  add_foreign_key "held_items", "source_descriptions", column: ["source_description_id", "catalogue_document_id"], primary_key: ["id", "catalogue_document_id"], name: "fk_f2_items_source_document"
  add_foreign_key "import_logs", "catalogue_documents"
  add_foreign_key "import_logs", "works"
  add_foreign_key "import_logs", "works", column: ["work_id", "catalogue_document_id"], primary_key: ["id", "catalogue_document_id"], name: "fk_import_logs_work_document"
  add_foreign_key "instrumentations", "works"
  add_foreign_key "movements", "works"
  add_foreign_key "performances", "works"
  add_foreign_key "source_descriptions", "catalogue_documents"
  add_foreign_key "source_references", "works"
  add_foreign_key "source_relations", "catalogue_documents"
  add_foreign_key "source_relations", "source_descriptions", column: ["source_description_id", "catalogue_document_id"], primary_key: ["id", "catalogue_document_id"], name: "fk_f2_relations_owner_document"
  add_foreign_key "source_relations", "source_descriptions", column: ["target_source_description_id", "catalogue_document_id"], primary_key: ["id", "catalogue_document_id"], name: "fk_f2_relations_source_target_document", on_delete: :restrict
  add_foreign_key "source_relations", "works", column: ["target_work_id", "catalogue_document_id"], primary_key: ["id", "catalogue_document_id"], name: "fk_f2_relations_work_target_document", on_delete: :restrict
  add_foreign_key "work_classification_terms", "works"
  add_foreign_key "work_titles", "works"
  add_foreign_key "works", "catalogue_documents"
  add_foreign_key "works", "composers"
end
