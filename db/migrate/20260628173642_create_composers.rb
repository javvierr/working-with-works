class CreateComposers < ActiveRecord::Migration[7.0]
  def change
    create_table :composers do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :composers, :name, unique: true
  end
end
