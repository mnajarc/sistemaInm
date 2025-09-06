class CreateOperationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :operation_types do |t|
      t.string :name
      t.string :display_name
      t.text :description
      t.boolean :active
      t.integer :sort_order

      t.timestamps
    end
    add_index :operation_types, :name, unique: true
  end
end
