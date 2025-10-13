class CreatePersonTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :person_types do |t|
      t.string :name, null: false # PF, PM, FIDE
      t.string :display_name, null: false # Persona Física, Persona Moral, Fideicomiso
      t.text :description
      t.string :tax_regime # Régimen fiscal aplicable
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :person_types, :name, unique: true
    add_index :person_types, :active
    add_index :person_types, :sort_order
  end
end