class CreateContractSignerTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_signer_types do |t|
      t.string :name, null: false # titular_registral, apoderado, representante_legal, etc.
      t.string :display_name, null: false
      t.text :description
      t.boolean :requires_power_of_attorney, default: false, null: false
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :contract_signer_types, :name, unique: true
    add_index :contract_signer_types, :requires_power_of_attorney
    add_index :contract_signer_types, :active
    add_index :contract_signer_types, :sort_order
  end
end