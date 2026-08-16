class CreateMovements < ActiveRecord::Migration[7.0]
  def change
    create_table :movements do |t|
      t.references :work, null: false, foreign_key: true
      t.integer :position
      t.string :title
      t.string :tempo_marking
      t.string :duration

      t.timestamps
    end

    add_index :movements, [:work_id, :position], unique: true
  end
end
