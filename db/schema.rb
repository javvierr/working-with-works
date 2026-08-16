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

ActiveRecord::Schema[7.0].define(version: 2026_06_28_173732) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "catalogue_identifiers", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "identifier_type"
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["value"], name: "index_catalogue_identifiers_on_value"
    t.index ["work_id", "value"], name: "index_catalogue_identifiers_on_work_id_and_value", unique: true
    t.index ["work_id"], name: "index_catalogue_identifiers_on_work_id"
  end

  create_table "composers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_composers_on_name", unique: true
  end

  create_table "external_references", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "label"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_external_references_on_url"
    t.index ["work_id"], name: "index_external_references_on_work_id"
  end

  create_table "import_logs", force: :cascade do |t|
    t.bigint "work_id"
    t.string "source_file", null: false
    t.string "status", null: false
    t.string "work_title"
    t.jsonb "warnings", default: [], null: false
    t.text "error_message"
    t.datetime "imported_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["imported_at"], name: "index_import_logs_on_imported_at"
    t.index ["source_file"], name: "index_import_logs_on_source_file"
    t.index ["status"], name: "index_import_logs_on_status"
    t.index ["work_id"], name: "index_import_logs_on_work_id"
  end

  create_table "instrumentations", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "name", null: false
    t.string "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_instrumentations_on_name"
    t.index ["work_id", "name"], name: "index_instrumentations_on_work_id_and_name", unique: true
    t.index ["work_id"], name: "index_instrumentations_on_work_id"
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.integer "position"
    t.string "title"
    t.string "tempo_marking"
    t.string "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id", "position"], name: "index_movements_on_work_id_and_position", unique: true
    t.index ["work_id"], name: "index_movements_on_work_id"
  end

  create_table "performances", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.date "performed_on"
    t.string "location"
    t.text "performers"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location"], name: "index_performances_on_location"
    t.index ["performed_on"], name: "index_performances_on_performed_on"
    t.index ["work_id"], name: "index_performances_on_work_id"
  end

  create_table "source_references", force: :cascade do |t|
    t.bigint "work_id", null: false
    t.string "label"
    t.string "source_type"
    t.text "description"
    t.string "repository"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type"], name: "index_source_references_on_source_type"
    t.index ["work_id"], name: "index_source_references_on_work_id"
  end

  create_table "works", force: :cascade do |t|
    t.bigint "composer_id", null: false
    t.string "title", null: false
    t.string "catalogue_number"
    t.string "composition_date"
    t.integer "composition_year"
    t.string "genre"
    t.string "source_file", null: false
    t.string "source_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catalogue_number"], name: "index_works_on_catalogue_number"
    t.index ["composer_id"], name: "index_works_on_composer_id"
    t.index ["composition_year"], name: "index_works_on_composition_year"
    t.index ["genre"], name: "index_works_on_genre"
    t.index ["source_file"], name: "index_works_on_source_file", unique: true
    t.index ["title"], name: "index_works_on_title"
  end

  add_foreign_key "catalogue_identifiers", "works"
  add_foreign_key "external_references", "works"
  add_foreign_key "import_logs", "works"
  add_foreign_key "instrumentations", "works"
  add_foreign_key "movements", "works"
  add_foreign_key "performances", "works"
  add_foreign_key "source_references", "works"
  add_foreign_key "works", "composers"
end
