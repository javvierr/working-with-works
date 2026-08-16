class CreatePerformances < ActiveRecord::Migration[7.0]
  def change
    create_table :performances do |t|
      t.references :work, null: false, foreign_key: true
      t.date :performed_on
      t.string :location
      t.text :performers
      t.text :note

      t.timestamps
    end

    add_index :performances, :performed_on
    add_index :performances, :location
  end
end
