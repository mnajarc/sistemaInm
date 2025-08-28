class CreateCommissions < ActiveRecord::Migration[8.0]
  def change
    create_table :commissions do |t|
      t.references :property, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2
      t.string :commission_type
      t.string :status
      t.datetime :paid_at

      t.timestamps
    end
  end
end
