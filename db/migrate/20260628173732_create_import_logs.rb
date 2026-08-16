class CreateImportLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :import_logs do |t|
      t.references :work, null: true, foreign_key: true
      t.string :source_file, null: false
      t.string :status, null: false
      t.string :work_title
      t.jsonb :warnings, null: false, default: []
      t.text :error_message
      t.datetime :imported_at, null: false

      t.timestamps
    end

    add_index :import_logs, :source_file
    add_index :import_logs, :status
    add_index :import_logs, :imported_at
  end
end
