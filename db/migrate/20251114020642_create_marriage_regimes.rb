class CreateMarriageRegimes < ActiveRecord::Migration[8.0]
  def change
    create_table :marriage_regimes do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      
      t.timestamps
    end
    
    add_index :marriage_regimes, :name, unique: true
    add_index :marriage_regimes, :active
  end
end
