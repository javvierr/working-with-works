class CreateCatalogueIdentifiers < ActiveRecord::Migration[7.0]
  def change
    create_table :catalogue_identifiers do |t|
      t.references :work, null: false, foreign_key: true
      t.string :identifier_type
      t.string :value, null: false

      t.timestamps
    end

    add_index :catalogue_identifiers, :value
    add_index :catalogue_identifiers, [:work_id, :value], unique: true
  end
end
