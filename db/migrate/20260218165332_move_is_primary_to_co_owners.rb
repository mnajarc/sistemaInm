class MoveIsPrimaryToCoOwners < ActiveRecord::Migration[8.0]
  def change
    # Agregar is_primary a business_transaction_co_owners
    add_column :business_transaction_co_owners, :is_primary, :boolean, default: false
    
    # Marcar el primer co_owner de cada transacción como principal
    reversible do |dir|
      dir.up do
        BusinessTransaction.find_each do |bt|
          first_co_owner = bt.business_transaction_co_owners.order(:id).first
          first_co_owner&.update_column(:is_primary, true)
        end
      end
    end
    
    # Opcional: Remover de business_transactions si existe
    remove_column :business_transactions, :is_primary, :boolean if column_exists?(:business_transactions, :is_primary)
  end
end
