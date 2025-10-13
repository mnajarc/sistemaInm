class CreateCivilStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :civil_statuses do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :civil_statuses, :name, unique: true
    add_index :civil_statuses, :active
    add_index :civil_statuses, :sort_order
  end
end