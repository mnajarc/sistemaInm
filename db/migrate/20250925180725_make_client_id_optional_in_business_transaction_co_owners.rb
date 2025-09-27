class MakeClientIdOptionalInBusinessTransactionCoOwners < ActiveRecord::Migration[8.0]
  def change
    change_column_null :business_transaction_co_owners, :client_id, true
  end
end
