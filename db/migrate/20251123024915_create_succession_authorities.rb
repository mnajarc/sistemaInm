class CreateSuccessionAuthorities < ActiveRecord::Migration[8.0]
  def change
    create_table :succession_authorities do |t|
      t.string :name, null: false
      t.string :display_name, null: false
      t.text :description
      t.string :category # judicial, notarial, etc
      t.boolean :active, default: true
      t.integer :sort_order, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :succession_authorities, :name, unique: true
    add_index :succession_authorities, :active
  end
end
