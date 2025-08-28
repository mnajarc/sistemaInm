class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :title
      t.text :description
      t.decimal :price, precision: 15, scale: 2
      t.string :property_type
      t.string :status
      t.text :address
      t.string :city
      t.string :state
      t.string :postal_code
      t.integer :bedrooms
      t.integer :bathrooms
      t.decimal :built_area_m2, precision: 10, scale: 2
      t.decimal :lot_area_m2, precision: 10, scale: 2
      t.integer :year_built
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
