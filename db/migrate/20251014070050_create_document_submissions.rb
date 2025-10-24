class CreateDocumentSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :document_submissions do |t|
      t.references :business_transaction, null: false, foreign_key: true
      t.references :document_type, null: false, foreign_key: true
      t.references :document_status, null: true, foreign_key: true
      t.string :party_type, null: false
      t.references :submitted_by, polymorphic: true, null: true
      t.datetime :submitted_at, null: true
      t.references :validated_by, null: true, foreign_key: { to_table: :users }
      t.datetime :validated_at, null: true
      t.date :expiry_date, null: true
      t.text :notes

      t.timestamps
    end

    add_index :document_submissions, [:business_transaction_id, :document_type_id, :party_type], 
              name: 'idx_submissions_transaction_document_party'
    add_index :document_submissions, :expiry_date
    add_index :document_submissions, :submitted_at
  end
end