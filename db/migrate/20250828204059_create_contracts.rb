class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.references :client, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.decimal :amount
      t.string :status

      t.timestamps
    end
  end
end
