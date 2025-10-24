class AddTransactionScenarioToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :business_transactions, :transaction_scenario, null: true, foreign_key: true
  end
end
