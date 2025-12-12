# db/migrate/[timestamp]_add_validation_status_to_document_submissions.rb
class AddValidationStatusToDocumentSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :document_submissions, :validation_status, :string, default: 'pending_review'
    add_column :document_submissions, :validated_notes, :text
    add_column :document_submissions, :last_note_at, :datetime
    
    add_index :document_submissions, :validation_status
  end
end
