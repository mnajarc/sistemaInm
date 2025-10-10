class OptimizeBusinessTransactionCoOwners < ActiveRecord::Migration[8.0]
  def change
    # Hacer percentage opcional (no siempre importa para el brokerage)
    change_column_null :business_transaction_co_owners, :percentage, true
    change_column_default :business_transaction_co_owners, :percentage, nil
    
    # Agregar índice compuesto para mejor rendimiento
    add_index :business_transaction_co_owners, 
              [:business_transaction_id, :active], 
              name: 'idx_co_owners_transaction_active'

  end
end
