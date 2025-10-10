class CreateOffers < ActiveRecord::Migration[8.0]
  def change
    create_table :offers do |t|
      t.references :business_transaction, null: false, foreign_key: true
      t.references :offerer, null: false, foreign_key: { to_table: :clients }
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :offer_date, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :valid_until
      t.text :terms
      t.text :notes
      t.integer :status, default: 0, null: false
      t.integer :queue_position

      t.timestamps
    end

    add_index :offers, [:business_transaction_id, :queue_position]
    add_index :offers, [:business_transaction_id, :status]
    add_index :offers, [:offerer_id, :status]
  end
end
