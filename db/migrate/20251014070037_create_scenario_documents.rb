class CreateScenarioDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :scenario_documents do |t|
      t.references :transaction_scenario, null: false, foreign_key: true
      t.references :document_type, null: false, foreign_key: true
      t.string :party_type, null: false, default: 'ambos'
      t.boolean :required, default: true
      t.text :notes

      t.timestamps
    end

    add_index :scenario_documents, [:transaction_scenario_id, :document_type_id], 
              name: 'idx_scenario_documents_scenario_document'
    add_index :scenario_documents, :party_type
  end
end
