class CreateDocumentRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :document_requirements do |t|
      t.references :document_type, null: false, foreign_key: true
      t.string :property_type
      t.string :transaction_type
      t.string :client_type
      t.string :person_type
      t.date :valid_from
      t.date :valid_until
      t.boolean :is_required
      t.string :applies_to

      t.timestamps
    end
  end
end
