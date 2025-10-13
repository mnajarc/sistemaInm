class UpdateDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    # Actualizar tabla existente de document_types con nuevos campos
    add_column :document_types, :requirement_context, :string, default: 'general'
    add_column :document_types, :applies_to_person_type, :string
    add_column :document_types, :applies_to_acquisition_type, :string
    add_column :document_types, :mandatory, :boolean, default: false
    add_column :document_types, :blocks_transaction, :boolean, default: false
    
    # Agregar índices
    add_index :document_types, :requirement_context
    add_index :document_types, :applies_to_person_type
    add_index :document_types, :mandatory
    add_index :document_types, :blocks_transaction
  end
end