# app/models/document_note.rb
class DocumentNote < ApplicationRecord
  belongs_to :document_submission
  belongs_to :user
  
  validates :content, presence: true
  validates :note_type, presence: true, inclusion: { in: %w[comment status_change] }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :comments, -> { where(note_type: 'comment') }
  scope :status_changes, -> { where(note_type: 'status_change') }
  
  # Solo el autor puede borrar su última nota propia
  def deletable_by?(user)
    self.user == user && self == document_submission.document_notes.recent.first
  end
end
