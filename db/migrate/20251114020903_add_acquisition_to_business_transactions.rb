class AddAcquisitionToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    # add_reference YA crea el índice automáticamente, así que no agregamos add_index después
    add_reference :business_transactions, :property_acquisition_method, foreign_key: true, null: true
    
    add_column :business_transactions, :acquisition_clarification, :text
    add_column :business_transactions, :initial_contact_folio, :string
    
    add_column :business_transactions, :inheritance_details, :jsonb, default: {}
    add_column :business_transactions, :property_status, :jsonb, default: {}
    add_column :business_transactions, :tax_information, :jsonb, default: {}
    add_column :business_transactions, :legal_representation, :jsonb, default: {}
    
    # NO agregar: add_index :business_transactions, :property_acquisition_method_id
    # Ya existe por add_reference
    
    # Solo agregar índice para initial_contact_folio (único)
    add_index :business_transactions, :initial_contact_folio, unique: true
    
    # Índices GIN para JSONB
    add_index :business_transactions, :inheritance_details, using: :gin
    add_index :business_transactions, :property_status, using: :gin
    add_index :business_transactions, :tax_information, using: :gin
    add_index :business_transactions, :legal_representation, using: :gin
  end
end