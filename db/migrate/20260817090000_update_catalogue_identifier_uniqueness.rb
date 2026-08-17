class UpdateCatalogueIdentifierUniqueness < ActiveRecord::Migration[7.0]
  OLD_INDEX_NAME = "index_catalogue_identifiers_on_work_id_and_value"
  NEW_INDEX_NAME = "index_catalogue_identifiers_on_work_type_value"

  def up
    execute <<~SQL
      UPDATE catalogue_identifiers
      SET identifier_type = 'catalogue'
      WHERE identifier_type IS NULL OR identifier_type ~ '^[[:space:]]*$'
    SQL

    remove_index :catalogue_identifiers, name: OLD_INDEX_NAME
    change_column_null :catalogue_identifiers, :identifier_type, false
    add_index :catalogue_identifiers,
      [:work_id, :identifier_type, :value],
      unique: true,
      name: NEW_INDEX_NAME
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Normalized identifier types and cross-type duplicate values cannot be reversed safely"
  end
end
