class FixDisplayNameInDocumentTypes < ActiveRecord::Migration[8.0]
  def up
    # 1. Asegurar que display_name exista siempre
    execute <<~SQL
      UPDATE document_types
      SET display_name = name
      WHERE display_name IS NULL OR display_name = '';
    SQL


    # 3. Crear índice para búsquedas por nombre visible
    add_index :document_types, :display_name
  end

  def down
    remove_index :document_types, :display_name
  end
end

