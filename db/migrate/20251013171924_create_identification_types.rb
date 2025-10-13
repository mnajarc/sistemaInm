class CreateIdentificationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :identification_types do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.string :issuing_authority
      t.integer :validity_years
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :identification_types, :name, unique: true
    add_index :identification_types, :active
    add_index :identification_types, :sort_order
  end
end