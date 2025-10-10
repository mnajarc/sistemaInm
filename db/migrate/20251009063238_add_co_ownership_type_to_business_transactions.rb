class AddCoOwnershipTypeToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :business_transactions, :co_ownership_type, null: true, foreign_key: true
  end
end
