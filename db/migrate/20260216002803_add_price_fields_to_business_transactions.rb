class AddPriceFieldsToBusinessTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :business_transactions, :market_analysis_price, :decimal, precision: 15, scale: 2
    add_column :business_transactions, :suggested_price, :decimal, precision: 15, scale: 2
  end
end
