class CreateTransactionScenarios < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_scenarios do |t|
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :transaction_scenarios, :name, unique: true
    add_index :transaction_scenarios, :category
  end
end
