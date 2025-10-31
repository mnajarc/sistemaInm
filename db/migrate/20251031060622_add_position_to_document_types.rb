class AddPositionToDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :document_types, :position, :integer, default: 0
    add_index :document_types, :position
    
    reversible do |dir|
      dir.up do
        # Asignar position basado en ID (orden de creación)
        # Los documentos más antiguos tendrán posición más baja
        DocumentType.order(:id).each.with_index(1) do |doc_type, index|
          doc_type.update_column(:position, index)
        end
        
        # Hacer NOT NULL después de asignar valores
        change_column_null :document_types, :position, false
      end
      
      dir.down do
        # Al revertir, permitir NULL temporalmente
        change_column_null :document_types, :position, true
      end
    end
  end
end