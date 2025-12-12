# db/migrate/[timestamp]_create_document_notes.rb
class CreateDocumentNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :document_notes do |t|
      t.references :document_submission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :note_type, default: 'comment'  # 'comment' o 'status_change'
      t.timestamps
    end
    
    add_index :document_notes, [:document_submission_id, :created_at]
  end
end
