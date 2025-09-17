class CreateCoOwnershipTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :co_ownership_types do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :active, default: true
      t.integer :sort_order, default: 10

      t.timestamps
    end
    
    add_index :co_ownership_types, :name, unique: true
    add_index :co_ownership_types, :active
  end
end
