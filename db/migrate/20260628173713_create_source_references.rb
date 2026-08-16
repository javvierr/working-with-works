class CreateSourceReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :source_references do |t|
      t.references :work, null: false, foreign_key: true
      t.string :label
      t.string :source_type
      t.text :description
      t.string :repository

      t.timestamps
    end

    add_index :source_references, :source_type
  end
end
