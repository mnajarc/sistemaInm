class AddAnalysisFieldsToDocumentSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :document_submissions, :analysis_status, :string, default: 'pending'
    add_column :document_submissions, :analysis_result, :jsonb, default: {}
    add_column :document_submissions, :ocr_text, :text
    add_column :document_submissions, :legibility_score, :decimal, precision: 5, scale: 2
    add_column :document_submissions, :auto_validated, :boolean, default: false
    add_column :document_submissions, :validation_notes, :text
    add_column :document_submissions, :analyzed_at, :datetime
    
    add_index :document_submissions, :analysis_status
    add_index :document_submissions, :legibility_score
    add_index :document_submissions, :auto_validated
  end
end
