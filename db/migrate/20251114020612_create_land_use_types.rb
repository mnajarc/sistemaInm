class CreateLandUseTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :land_use_types do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      
      # Jerarquía
      t.references :parent, foreign_key: { to_table: :land_use_types }, null: true
      t.string :category
      
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      
      t.timestamps
    end
    
    add_index :land_use_types, :code, unique: true
    add_index :land_use_types, :category
    add_index :land_use_types, [:parent_id, :active]
  end
end

