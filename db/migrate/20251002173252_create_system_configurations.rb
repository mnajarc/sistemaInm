class CreateSystemConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :system_configurations do |t|
      t.string :key, null: false, index: { unique: true }
      t.text :value, null: false
      t.string :value_type, null: false, default: 'string'
      t.string :category, null: false
      t.text :description, null: false
      t.boolean :active, default: true, null: false
      t.boolean :system_config, default: false, null: false
      t.json :environments # Para configuraciones específicas por ambiente
      t.json :metadata # Información adicional (validaciones, opciones, etc.)
      t.integer :sort_order, default: 0
      
      t.timestamps
    end
    
    add_index :system_configurations, :category
    add_index :system_configurations, :active
    add_index :system_configurations, :system_config
  end
end