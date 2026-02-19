# db/migrate/XXXXXXXXXXXXXX_create_countries.rb
class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name,        null: false  # "México"
      t.string :alpha2_code, null: false  # "MX"
      t.string :alpha3_code               # "MEX"
      t.string :nationality               # "Mexicana"

      t.timestamps
    end

    add_index :countries, :alpha2_code, unique: true
    add_index :countries, :alpha3_code, unique: true
    add_index :countries, :name
  end
end

