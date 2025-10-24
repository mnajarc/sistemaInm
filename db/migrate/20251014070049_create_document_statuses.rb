class CreateDocumentStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :document_statuses do |t|
      t.string :name, null: false
      t.text :description
      t.string :color, default: 'secondary'
      t.string :icon, default: 'circle'
      t.integer :position, null: false, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :document_statuses, :name, unique: true
    add_index :document_statuses, :position
  end
end