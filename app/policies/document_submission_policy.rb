# app/policies/document_submission_policy.rb
class DocumentSubmissionPolicy < ApplicationPolicy
    def index?
      user.agent? || user.admin? || user.superadmin?
    end
  
    def show?
      owner_or_admin?
    end
  
    def upload?
      owner_or_admin?
    end
  
    def preview?
      owner_or_admin?
    end
  
    def download?
      owner_or_admin?
    end
  
    def approve?
      user.admin? || user.superadmin?
    end
  
    def reject?
      user.admin? || user.superadmin?
    end
  
    def mark_expired?
      user.admin? || user.superadmin?
    end
  
    def add_note?
      user.agent? || user.admin? || user.superadmin?
    end
  
    def delete_note?
      add_note? && (record.document_notes.recent.first&.user == user)
    end
  
    private
  
    def owner_or_admin?
      user.admin? || user.superadmin? || 
      record.business_transaction.assigned_agent == user
    end
  end
  