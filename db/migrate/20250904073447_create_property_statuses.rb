class CreatePropertyStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :property_statuses do |t|
      t.string :name
      t.string :display_name
      t.text :description
      t.string :color
      t.boolean :is_available
      t.boolean :active
      t.integer :sort_order

      t.timestamps
    end
    add_index :property_statuses, :name, unique: true
  end
end
