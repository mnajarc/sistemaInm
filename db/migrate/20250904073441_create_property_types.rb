class CreatePropertyTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :property_types do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :active, default: true
      t.integer :sort_order, default: 0

      t.timestamps
    end
    add_index :property_types, :name, unique: true
    add_index :property_types, :active
    add_index :property_types, :sort_order
  end
end
