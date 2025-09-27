class AddMultipleAgentsToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    # Eliminar solo la columna, no la foreign key (no existe)
    if column_exists?(:business_transactions, :agent_id)
      remove_column :business_transactions, :agent_id
    end

    # Agregar las nuevas referencias
    add_reference :business_transactions, :listing_agent, null: false, foreign_key: { to_table: :users }
    add_reference :business_transactions, :current_agent, null: false, foreign_key: { to_table: :users }
    add_reference :business_transactions, :selling_agent, null: true, foreign_key: { to_table: :users }
  end
end
