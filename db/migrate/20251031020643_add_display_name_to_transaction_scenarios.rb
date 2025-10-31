class AddDisplayNameToTransactionScenarios < ActiveRecord::Migration[8.0]
  def change
    add_column :transaction_scenarios, :display_name, :string
    add_index :transaction_scenarios, :display_name
    
    # Datos existentes se migrarán en paso posterior
    reversible do |dir|
      dir.up do
        # Los datos se corrigen con script Ruby en db/seeds/
      end
    end
  end
end
