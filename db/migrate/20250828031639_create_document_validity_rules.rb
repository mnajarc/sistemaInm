class CreateDocumentValidityRules < ActiveRecord::Migration[8.0]
  def change
    create_table :document_validity_rules do |t|
      t.references :document_type, null: false, foreign_key: true
      t.integer :validity_period_months
      t.date :valid_from
      t.date :valid_until
      t.boolean :is_active

      t.timestamps
    end
  end
end
