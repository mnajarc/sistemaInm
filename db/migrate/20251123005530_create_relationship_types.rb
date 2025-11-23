class CreateRelationshipTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :relationship_types do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.string :category # copropietario, heredero, donante, etc
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :relationship_types, :name, unique: true
    add_index :relationship_types, :active
    add_index :relationship_types, :category
  end
end
