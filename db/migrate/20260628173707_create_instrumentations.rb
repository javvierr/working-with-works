class CreateInstrumentations < ActiveRecord::Migration[7.0]
  def change
    create_table :instrumentations do |t|
      t.references :work, null: false, foreign_key: true
      t.string :name, null: false
      t.string :section

      t.timestamps
    end

    add_index :instrumentations, :name
    add_index :instrumentations, [:work_id, :name], unique: true
  end
end
