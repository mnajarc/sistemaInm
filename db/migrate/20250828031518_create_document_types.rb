class CreateDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :document_types do |t|
      t.string :name
      t.text :description
      t.string :category
      t.date :valid_from
      t.date :valid_until
      t.integer :replacement_document_id
      t.boolean :is_active

      t.timestamps
    end
  end
end
