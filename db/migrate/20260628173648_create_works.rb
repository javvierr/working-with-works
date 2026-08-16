class CreateWorks < ActiveRecord::Migration[7.0]
  def change
    create_table :works do |t|
      t.references :composer, null: false, foreign_key: true
      t.string :title, null: false
      t.string :catalogue_number
      t.string :composition_date
      t.integer :composition_year
      t.string :genre
      t.string :source_file, null: false
      t.string :source_identifier

      t.timestamps
    end

    add_index :works, :title
    add_index :works, :catalogue_number
    add_index :works, :composition_year
    add_index :works, :genre
    add_index :works, :source_file, unique: true
  end
end
