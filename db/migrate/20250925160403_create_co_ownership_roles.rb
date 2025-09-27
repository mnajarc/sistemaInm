class CreateCoOwnershipRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :co_ownership_roles do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0, null: false

      t.timestamps
    end

      add_index :co_ownership_roles, :name, unique: true
      add_index :co_ownership_roles, :active
      add_index :co_ownership_roles, :sort_order
  end
end
