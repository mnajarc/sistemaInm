class AddTransactionDetailsToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    # Información del contrato
    add_column :business_transactions, :external_operation_number, :string
    add_column :business_transactions, :contract_signer_type, :string
    add_column :business_transactions, :c21_legal_representative, :string
    add_column :business_transactions, :contract_days_term, :integer
    add_column :business_transactions, :contract_expiration_date, :date
    add_column :business_transactions, :celebration_place, :string
    
    # Información comercial detallada
    add_column :business_transactions, :commission_amount, :decimal, precision: 15, scale: 2
    add_column :business_transactions, :commission_vat, :decimal, precision: 15, scale: 2
    add_column :business_transactions, :recommended_price, :decimal, precision: 15, scale: 2
    add_column :business_transactions, :payment_method, :string
    
    # Datos de escrituración de la propiedad
    add_column :business_transactions, :deed_number, :string
    add_column :business_transactions, :deed_date, :date
    add_column :business_transactions, :notary_number, :string
    add_column :business_transactions, :notary_name, :string
    add_column :business_transactions, :notary_location, :string
    add_column :business_transactions, :real_folio, :string
    add_column :business_transactions, :property_registry_location, :string
    add_column :business_transactions, :registration_date, :date
    
    # Información de adquisición de la propiedad
    add_column :business_transactions, :acquisition_legal_act, :string
    add_column :business_transactions, :acquisition_date, :date
    add_column :business_transactions, :is_mortgaged_at_transaction, :boolean, default: false
    add_column :business_transactions, :has_liens_at_transaction, :boolean, default: false
    
    # Índices importantes
    add_index :business_transactions, :external_operation_number, unique: true
    add_index :business_transactions, :contract_expiration_date
    add_index :business_transactions, :deed_number
    add_index :business_transactions, :real_folio
    add_index :business_transactions, :acquisition_legal_act
    add_index :business_transactions, :is_mortgaged_at_transaction
  end
end