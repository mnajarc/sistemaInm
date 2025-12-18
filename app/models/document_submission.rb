# ✅ MODELO CONSOLIDADO Y CORREGIDO
# app/models/document_submission.rb

class DocumentSubmission < ApplicationRecord
  # ========================================================================
  # RELACIONES
  # ========================================================================
  
  belongs_to :business_transaction
  belongs_to :document_type
  belongs_to :document_status, optional: true
  belongs_to :submitted_by, polymorphic: true, optional: true
  belongs_to :validated_by, class_name: 'User', optional: true
  belongs_to :uploaded_by, class_name: 'User', optional: true, 
             foreign_key: 'uploaded_by_id'
  belongs_to :business_transaction_co_owner, optional: true
  belongs_to :validation_user, class_name: 'User', optional: true, 
             foreign_key: 'validation_user_id'

  has_many :document_notes, dependent: :destroy
  has_many :document_reviews, dependent: :destroy

  # Active Storage
  has_one_attached :document_file do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :medium, resize_to_limit: [800, 800]
  end

  # ========================================================================
  # VALIDACIONES
  # ========================================================================
  
  validates :party_type, presence: true, inclusion: { 
    in: %w[oferente adquiriente copropietario copropietario_principal]
  }
  
  validates :business_transaction_co_owner_id, 
    presence: true, 
    if: -> { party_type.in?(%w[copropietario copropietario_principal]) }
  
  validates :analysis_status, 
    inclusion: { in: %w[pending processing completed failed] },
    allow_nil: true
  
  validates :validation_status, presence: true, inclusion: {
    in: %w[pending_review approved rejected expired]
  }, allow_nil: true

  validates :business_transaction_id, presence: true
  validates :document_type_id, presence: true

  # Active Storage validations
  validate :validate_document_file_type
  validate :validate_document_file_size

  # ========================================================================
  # SCOPES - SIN DUPLICADOS
  # ========================================================================
  
  # Por partido (oferente/adquiriente/copropietario)
  scope :for_oferente, -> { where(party_type: 'oferente') }
  scope :for_adquiriente, -> { where(party_type: 'adquiriente') }
  scope :for_copropietario, -> { where(party_type: ['copropietario', 'copropietario_principal']) }
  scope :for_co_owner, ->(co_owner) { where(business_transaction_co_owner: co_owner) }
  scope :by_party, ->(party) { where(party_type: party) }

  # Por estado del documento
  scope :pending, -> { 
    joins(:document_status).where(document_statuses: { name: 'pendiente_solicitud' }) 
  }
  scope :completed, -> { 
    joins(:document_status).where(document_statuses: { name: 'validado_vigente' }) 
  }
  scope :validated, -> { 
    where.not(validated_at: nil).where(validation_status: 'approved')
  }
  scope :rejected, -> { 
    where(validation_status: 'rejected')
  }

  # Por carga del documento
  scope :pending_upload, -> { where(submitted_at: nil) }
  scope :uploaded, -> { where.not(submitted_at: nil) }

  # Por análisis
  scope :pending_analysis, -> { where(analysis_status: 'pending') }
  scope :analyzed, -> { where.not(analysis_status: 'pending') }
  scope :auto_validated, -> { where(auto_validated: true) }
  scope :pending_validation, -> { where(validation_status: ['pending_review', nil]) }

  # Por fecha de expiración
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  scope :expiring_soon, -> { where('expiry_date BETWEEN ? AND ?', Date.current, 30.days.from_now) }
  scope :valid_date, -> { where('expiry_date IS NULL OR expiry_date >= ?', Date.current) }

  # ========================================================================
  # CALLBACKS
  # ========================================================================
  
  before_create :set_default_status
  after_create_commit :schedule_analysis, if: :document_file_attached?
  after_update :notify_status_change, if: :saved_change_to_document_status_id?

  # ========================================================================
  # MÉTODOS DE ESTADO - SIN DUPLICADOS
  # ========================================================================

  # Verifica si el documento ha sido analizado
  def analyzed?
    analysis_status.present? && analysis_status != 'pending'
  end

  # Verifica si el documento está expirado
  def expired?
    return false unless expiry_date.present?
    expiry_date < Date.current
  end

  # Verifica si está próximo a expirar (30 días)
  def expiring_soon?
    return false unless expiry_date.present?
    days_until_expiry = (expiry_date - Date.current).to_i
    days_until_expiry >= 0 && days_until_expiry <= 30
  end

  # Verifica si fue validado
  def validated?
    validated_at.present? && validation_status == 'approved'
  end

  # Verifica si el documento es válido para usar (MÉTODO CRÍTICO)
  def valid_for_use?
    uploaded? && validated? && !expired?
  end

  # ========================================================================
  # MÉTODOS DE ESTADO - COMPATIBILIDAD
  # ========================================================================

  def pending?
    document_status&.name == 'pendiente_solicitud'
  end
  
  def completed?
    document_status&.name.in?(['validado_vigente', 'validado'])
  end
  
  def uploaded?
    submitted_at.present?
  end
  
  def pending_validation?
    uploaded? && validation_status.in?(['pending_review', nil])
  end
  
  def has_files?
    document_file.attached?
  end

  # ========================================================================
  # MÉTODOS DE LEGIBILIDAD Y ANÁLISIS
  # ========================================================================

  def legibility_status
    return 'unknown' if legibility_score.nil? || legibility_score.zero?
    
    case legibility_score
    when 0...40 then 'poor'
    when 40...70 then 'fair'
    when 70...90 then 'good'
    else 'excellent'
    end
  end

  def analysis_status_label
    case analysis_status
    when 'pending' then 'Pendiente'
    when 'processing' then 'Procesando'
    when 'completed' then 'Completado'
    when 'failed' then 'Error'
    else 'Desconocido'
    end
  end

  # ========================================================================
  # MÉTODOS DE CAMBIO DE ESTADO
  # ========================================================================
  
  def mark_as_received!
    return unless document_status
    
    update!(
      document_status: DocumentStatus.find_by(name: 'recibido_revision'),
      submitted_at: Time.current
    )
  end
  
  def mark_as_validated!(user, notes: nil)
    update!(
      document_status: DocumentStatus.find_by(name: 'validado'),
      validated_by: user,
      validated_at: Time.current,
      validation_notes: notes,
      validation_status: 'approved'
    )
  end
  
  def reject!(reason, user)
    document_reviews.create!(
      user: user,
      action: 'rechazado',
      notes: reason
    )
    
    update!(
      document_status: DocumentStatus.find_by(name: 'rechazado'),
      validated_by: user,
      validated_at: Time.current,
      validation_notes: reason,
      validation_status: 'rejected'
    )
  end

  # ========================================================================
  # MÉTODOS DE VISUALIZACIÓN Y FORMATO
  # ========================================================================

  def status_badge_class
    return 'bg-secondary' unless uploaded?
    
    case validation_status
    when 'approved' then 'bg-success'
    when 'rejected' then 'bg-danger'
    when 'expired' then 'bg-dark'
    when 'pending_review' then 'bg-warning'
    else 'bg-info'
    end
  end

  def party_display_name
    case party_type
    when 'oferente'
      business_transaction_co_owner.present? ? 
        "#{business_transaction_co_owner.person_name} (Copropietario)" : 
        'Oferente'
    when 'adquiriente'
      'Adquiriente'
    when 'copropietario', 'copropietario_principal'
      business_transaction_co_owner.present? ? 
        business_transaction_co_owner.person_name : 
        'Copropietario'
    else
      party_type.titleize
    end
  end

  def download_url
    Rails.application.routes.url_helpers.rails_blob_path(
      document_file, 
      disposition: 'attachment'
    ) if uploaded?
  end
  
  def can_reupload?
    validation_status.in?(['rejected', 'expired']) || submitted_at.blank?
  end

  # ========================================================================
  # MÉTODOS DE NOTAS Y REVIEWS
  # ========================================================================

  def latest_review
    document_reviews.recent.first
  end

  def reviews_count
    document_reviews.count
  end

  def reviewed_by?(user)
    document_reviews.exists?(user: user)
  end

  def review_history
    document_reviews.recent.includes(:user)
  end

  def last_note
    document_notes.recent.first
  end

  def add_note(user, content, note_type = 'comment')
    document_notes.create!(
      user: user,
      content: content,
      note_type: note_type
    )
  end

  # ========================================================================
  # MÉTODOS PRIVADOS
  # ========================================================================
  
  private
  
  def validate_document_file_type
    return unless document_file.attached?
    
    allowed_types = %w[image/png image/jpg image/jpeg application/pdf image/heic]
    unless allowed_types.include?(document_file.content_type)
      errors.add(:document_file, 'debe ser PNG, JPG, HEIC o PDF')
    end
  end
  
  def validate_document_file_size
    return unless document_file.attached?
    
    if document_file.byte_size > 10.megabytes
      errors.add(:document_file, 'no debe exceder 10MB')
    end
  end
  
  def schedule_analysis
    DocumentAnalysisJob.perform_later(id) if defined?(DocumentAnalysisJob)
  end
  
  def document_file_attached?
    document_file.attached?
  end

  def set_default_status
    self.document_status ||= DocumentStatus.find_by(name: 'pendiente_solicitud')
    self.analysis_status ||= 'pending'
    self.validation_status ||= 'pending_review'
  end

  def notify_status_change
    # DocumentStatusNotificationJob.perform_later(self.id)
  end
end
