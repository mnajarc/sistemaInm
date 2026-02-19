# db/migrate/XXXXXXXXXXXXXX_create_addresses.rb
class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string :street
      t.string :exterior_number
      t.string :interior_number
      t.string :neighborhood        # colonia
      t.string :municipality         # alcaldía / municipio
      t.string :state
      t.string :country, default: "México"
      t.string :postal_code
      t.string :notes                # entre calles, referencia, etc.

      t.timestamps
    end

    add_index :addresses, :postal_code
    add_index :addresses, [:street, :exterior_number, :postal_code],
              name: "idx_addresses_lookup"
  end
end

