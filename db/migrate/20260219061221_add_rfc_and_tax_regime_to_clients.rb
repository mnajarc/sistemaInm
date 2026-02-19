# db/migrate/XXXXXXXXXXXXXX_add_rfc_and_tax_regime_to_clients.rb
class AddRfcAndTaxRegimeToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :rfc, :string
    add_column :clients, :tax_regime, :string

    add_index :clients, :rfc # sin unique por ahora
  end
end
