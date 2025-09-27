class CreateAgentTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_transfers do |t|
      t.references :business_transaction, null: false, foreign_key: true
      t.references :from_agent, null: false, foreign_key: { to_table: :users }
      t.references :to_agent, null: false, foreign_key: { to_table: :users }
      t.references :transferred_by, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.datetime :transferred_at, null: false

      t.timestamps
    end

    add_index :agent_transfers, [ :business_transaction_id, :transferred_at ]
  end
end
