# db/migrate/XXXXXXXXXXXXXX_create_client_addresses.rb
class CreateClientAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :client_addresses do |t|
      t.references :client,  null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.string :address_type, null: false  # 'fiscal', 'particular', 'comercial', 'legal'

      t.timestamps
    end

    add_index :client_addresses, [:client_id, :address_type]
    add_index :client_addresses, [:client_id, :address_id, :address_type],
              unique: true,
              name: "idx_client_addresses_unique"
  end
end

