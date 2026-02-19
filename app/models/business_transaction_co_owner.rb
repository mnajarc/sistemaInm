class BusinessTransactionCoOwner < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :client, optional: true
  belongs_to :co_ownership_role, foreign_key: 'role', primary_key: 'name', optional: true

  has_many :document_submissions, dependent: :destroy


  # validates :business_transaction_id, presence: true
  # validates :percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :person_name, presence: true, if: -> { client_id.blank? }
  validates :role, presence: true, unless: -> { marked_for_destruction? }
  validates :percentage, 
    numericality: { greater_than: 0, less_than_or_equal_to: 100, allow_blank: false },
    unless: -> { marked_for_destruction? }


  before_save :ensure_person_name 
  before_update :preserve_documents_on_client_change
  before_validation :set_default_role, on: :create


  scope :active, -> { where(active: true) }
  scope :principal, -> { where(is_primary: true) }
  scope :additional, -> { where(is_primary: false) }

  def should_be_primary?
    percentage == 100 || role == 'propietario' || role == 'vendedor'
  end

  def primary?
    is_primary == true
  end

  alias_method :is_primary?, :primary?

  def display_name
    client&.display_name || person_name || "Sin nombre"
  end

  def display_info
    "#{display_name} (#{percentage}%)"
  end


  # =================================================================
  # HELPERS PARA RÉGIMEN MATRIMONIAL
  # =================================================================

  def is_mancomunado?
    person_name == 'Cónyuge - Por definir' && role == 'copropietario'
  end

  def regime_label
    if is_mancomunado?
      'Sociedad Conyugal (Bienes Mancomunados)'
    else
      'Copropietario Comercial / Soltero'
    end
  end

  scope :mancomunados, lambda {
    where("person_name = ?", 'Cónyuge - Por definir').where(role: 'copropietario')
  }

  scope :copropietarios_comerciales, lambda {
    where("person_name != ?", 'Cónyuge - Por definir')
  }



  private


  # ============================================================
  # Asegurar que person_name siempre tenga valor
  # ============================================================
  

  def ensure_person_name
    return if person_name.present?
    
    if client.present?
      self.person_name = client.display_name || 
                         [client.first_names, client.first_surname, client.second_surname]
                           .compact.join(' ').strip ||
                         client.email ||
                         "Cliente #{client.id}"
    end
  end

  def preserve_documents_on_client_change
    return unless client_id_changed? && document_submissions.any?
    
    Rails.logger.warn "⚠️  Copropietario #{id} cambió de cliente (#{client_id_was} → #{client_id})"
    Rails.logger.warn "   Tiene #{document_submissions.count} documentos que permanecerán vinculados"
  end

  
  def ensure_person_name_anterior
    return if person_name.present?  # Si ya tiene valor, no hacer nada
    
    # Si tiene cliente vinculado, usa su nombre
    if client.present?
      self.person_name = client.display_name || 
                         [client.first_names, client.first_surname, client.second_surname]
                           .compact.join(' ').strip ||
                         client.email ||
                         "Cliente #{client.id}"
    end
    
    # Si no tiene cliente, mantener person_name como fue asignado
  end

  def preserve_documents_on_client_change_anterior
    return unless client_id_changed? && document_submissions.any?
    
    Rails.logger.warn "⚠️  ADVERTENCIA: Copropietario #{id} cambió de cliente (#{client_id_was} → #{client_id})"
    Rails.logger.warn "   Tiene #{document_submissions.count} documentos que permanecerán vinculados"
    
    # Los documentos permanecen vinculados al BusinessTransactionCoOwner
    # NO se borran, solo se actualiza la referencia del cliente
  end

  # ✅ NUEVO: Asignar rol por defecto si viene vacío
  def set_default_role
    if role.blank? && client.present?
      # Inferir rol del contexto de la transacción
      self.role = 'copropietario'
    end
  end


end
