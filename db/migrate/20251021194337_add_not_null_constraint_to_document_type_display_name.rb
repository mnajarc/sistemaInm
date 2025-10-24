class AddNotNullConstraintToDocumentTypeDisplayName < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE document_types SET display_name = name WHERE display_name IS NULL OR display_name = '';"
    change_column_null :document_types, :display_name, false
  end

  def down
    change_column_null :document_types, :display_name, true
  end
end
