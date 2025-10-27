# app/models/business_transaction_co_owner.rb
class BusinessTransactionCoOwner < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :client, optional: true
  belongs_to :co_ownership_role, foreign_key: 'role', primary_key: 'name', optional: true

  validates :person_name, presence: true, if: -> { client_id.blank? }
  validates :percentage, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 100 
  }, presence: true
  validates :role, presence: true

  scope :active, -> { where(active: true) }
  scope :deceased, -> { where(deceased: true) }
  scope :alive, -> { where(deceased: false) }
  scope :by_role, ->(role) { where(role: role) }

  def display_name
    client&.name || person_name
  end

  def display_info
    info = display_name
    info += " (#{percentage}%)" if percentage.present?
    info += " - FINADO" if deceased?
    info += " - #{role.upcase}" if role.present?
    info
  end

  def role_display_name
    co_ownership_role&.display_name || role&.humanize || 'Sin especificar'
  end

  def deceased?
    deceased == true
  end

  def alive?
    !deceased?
  end

  # ✅ MÉTODO PARA DOCUMENTOS REQUERIDOS
  def required_documents
    DocumentRequirement.where(
      transaction_type: business_transaction.operation_type.name,
      client_type: 'oferente', # Los copropietarios son siempre oferentes
      person_type: client&.person_type || 'fisico' # Default físico
    )
  end

  def documents_checklist
    required_documents.map do |req|
      {
        document_type: req.document_type,
        required: req.is_required,
        uploaded: client&.documents&.where(document_type: req.document_type)&.exists? || false
      }
    end
  end
end
