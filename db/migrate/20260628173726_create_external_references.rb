class CreateExternalReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :external_references do |t|
      t.references :work, null: false, foreign_key: true
      t.string :label
      t.string :url

      t.timestamps
    end

    add_index :external_references, :url
  end
end
