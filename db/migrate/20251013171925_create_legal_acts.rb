class CreateLegalActs < ActiveRecord::Migration[8.0]
  def change
    create_table :legal_acts do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.string :category # Oneroso, Gratuito, Judicial, etc.
      t.boolean :requires_notary, default: true, null: false
      t.boolean :active, default: true, null: false
      t.integer :sort_order, default: 0
      t.timestamps
    end
    
    add_index :legal_acts, :name, unique: true
    add_index :legal_acts, :category
    add_index :legal_acts, :active
    add_index :legal_acts, :sort_order
  end
end