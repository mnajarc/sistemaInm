class CreateSuccessionTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :succession_types do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.boolean :requires_judicial, default: false
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :succession_types, :name, unique: true
    add_index :succession_types, :active
  end
end
