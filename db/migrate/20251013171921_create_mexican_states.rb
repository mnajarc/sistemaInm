class CreateMexicanStates < ActiveRecord::Migration[8.0]
  def change
    create_table :mexican_states do |t|
      t.string :name, null: false
      t.string :code, null: false, limit: 5
      t.string :full_name, null: false
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :mexican_states, :code, unique: true
    add_index :mexican_states, :name, unique: true
    add_index :mexican_states, :active
  end
end