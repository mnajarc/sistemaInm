class CreateBusinessTransactionCoOwners < ActiveRecord::Migration[8.0]
  def change
    create_table :business_transaction_co_owners do |t|
      t.references :business_transaction, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :person_name
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.string :role
      t.boolean :deceased, default: false, null: false
      t.text :inheritance_case_notes
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
