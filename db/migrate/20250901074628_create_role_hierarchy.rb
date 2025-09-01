class CreateRoleHierarchy < ActiveRecord::Migration[8.0]
  def change
    # Tabla de roles configurables
    create_table :roles do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.integer :level, null: false, default: 999 # Menor número = mayor poder
      t.boolean :active, default: true
      t.boolean :system_role, default: false # No se puede eliminar
      t.timestamps
    end
    
    # Tabla de menús configurables
    create_table :menu_items do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.string :path
      t.string :icon
      # ✅ CORREGIDO: Separate reference and foreign key
      t.integer :parent_id, null: true
      t.integer :sort_order, default: 0
      t.integer :minimum_role_level, default: 999 # Nivel mínimo requerido
      t.boolean :active, default: true
      t.boolean :system_menu, default: false # No se puede eliminar
      t.timestamps
    end
    
    # Relación muchos a muchos: roles pueden ver ciertos menús
    create_table :role_menu_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :menu_item, null: false, foreign_key: true
      t.boolean :can_view, default: true
      t.boolean :can_edit, default: false
      t.timestamps
    end
    
    # ✅ Agregar foreign keys e índices después
    add_foreign_key :menu_items, :menu_items, column: :parent_id
    
    # Índices
    add_index :roles, :name, unique: true
    add_index :roles, :level
    add_index :menu_items, :name, unique: true
    add_index :menu_items, :parent_id
    add_index :menu_items, :sort_order
    add_index :menu_items, :minimum_role_level
    add_index :role_menu_permissions, [:role_id, :menu_item_id], 
              unique: true, name: 'idx_role_menu_unique'
  end
end
