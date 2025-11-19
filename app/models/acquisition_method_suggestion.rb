class AcquisitionMethodSuggestion < ApplicationRecord
    belongs_to :user
    belongs_to :initial_contact_form, optional: true
    belongs_to :merged_with, class_name: 'PropertyAcquisitionMethod', optional: true
    belongs_to :reviewed_by, class_name: 'User', optional: true
    
    enum status: { pending: 'pending', approved: 'approved', rejected: 'rejected', merged: 'merged' }
    
    validates :suggested_name, :legal_basis, presence: true
    
    scope :pending_review, -> { where(status: 'pending') }
    scope :ordered, -> { order(created_at: :desc) }
  end
  
  