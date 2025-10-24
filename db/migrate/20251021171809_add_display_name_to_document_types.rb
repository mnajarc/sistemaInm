class AddDisplayNameToDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :document_types, :display_name, :string
    
    # Poblar display_name con name para registros existentes
    reversible do |dir|
      dir.up do
        execute "UPDATE document_types SET display_name = name WHERE display_name IS NULL"
      end
    end
  end
end