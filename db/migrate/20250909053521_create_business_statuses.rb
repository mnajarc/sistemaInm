class CreateBusinessStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :business_statuses do |t|
      t.string  :name,         null: false
      t.string  :display_name, null: false
      t.text    :description
      t.string  :color,        default: 'secondary'
      t.boolean :active,       default: true
      t.integer :sort_order,   default: 0

      t.timestamps
    end

    add_index :business_statuses, :name, unique: true
    add_index :business_statuses, :active
    add_index :business_statuses, :sort_order
  end
end
