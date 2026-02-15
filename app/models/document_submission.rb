# app/models/document_submission.rb
# VERSIÓN LIMPIA: SIN validation_status ENUM - SOLO document_status
#
# ========================================================================
# CAMPOS DE VALIDACIÓN (dos flujos posibles)
# ========================================================================
# validated_by_id    → Usuario que APROBÓ/RECHAZÓ el documento (acción final)
# validation_user_id → Usuario que REVISÓ el documento (auditoría/supervisión)
# validated_at       → Timestamp de la acción de validación
# auto_validated     → Boolean - ¿fue aprobado automáticamente por OCR?
# validation_notes   → Notas de la validación (motivo rechazo, observaciones)
# validated_notes    → [LEGACY - Verificar si se usa. Candidata a deprecar]
#
# FLUJO MANUAL:   Admin revisa → mark_as_validated!(admin)
#                  → validated_by = admin, validation_user = admin
# FLUJO AUTO:     OCR aprueba → mark_as_auto_validated!(result)
#                  → validated_by = nil, auto_validated = true
# FLUJO MIXTO:    OCR pre-valida → Admin confirma → mark_as_validated!(admin)
#                  → auto_validated queda true, validation_user = admin
# ========================================================================

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

  validates :document_type_id,
            uniqueness: {
              scope: [:business_transaction_id, :business_transaction_co_owner_id],
              message: 'ya fue asignado a este copropietario en esta transacción'
            },
            if: -> { business_transaction_co_owner_id.present? }

  validates :document_type_id,
            uniqueness: {
              scope: [:business_transaction_id, :party_type],
              message: 'ya fue asignado para este tipo de parte en esta transacción'
            },
            if: -> { business_transaction_co_owner_id.nil? }

  validates :party_type, presence: true, inclusion: {
    in: %w[oferente adquiriente copropietario copropietario_principal]
  }

  validates :business_transaction_co_owner_id,
    presence: true,
    if: -> { party_type.in?(%w[copropietario copropietario_principal]) }

  validates :analysis_status,
    inclusion: { in: %w[pending processing completed failed] },
    allow_nil: true

  validates :business_transaction_id, presence: true
  validates :document_type_id, presence: true

  validate :validate_document_file_type
  validate :validate_document_file_size

  # ========================================================================
  # SCOPES
  # ========================================================================

  # Por party_type
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
    joins(:document_status).where(document_statuses: { name: 'validado_vigente' })
  }
  scope :rejected, -> {
    joins(:document_status).where(document_statuses: { name: 'rechazado' })
  }

  # Por carga del documento
  scope :pending_upload, -> { where(submitted_at: nil) }
  scope :uploaded, -> { where.not(submitted_at: nil) }

  # Por análisis
  scope :pending_analysis, -> { where(analysis_status: 'pending') }
  scope :analyzed, -> { where.not(analysis_status: 'pending') }
  scope :auto_validated, -> { where(auto_validated: true) }
  scope :pending_validation, -> {
    joins(:document_status).where(document_statuses: { name: 'pendiente_validacion' })
  }

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
  # MÉTODOS DE ESTADO
  # ========================================================================

  def analyzed?
    analysis_status.present? && analysis_status != 'pending'
  end

  def expired?
    return false unless expiry_date.present?
    expiry_date < Date.current
  end

  def expiring_soon?
    return false unless expiry_date.present?
    days_until_expiry = (expiry_date - Date.current).to_i
    days_until_expiry >= 0 && days_until_expiry <= 30
  end

  def validated?
    validated_at.present? && document_status&.name == 'validado_vigente'
  end

  def valid_for_use?
    uploaded? && validated? && !expired?
  end

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
    uploaded? && document_status&.name == 'pendiente_validacion'
  end

  def has_files?
    document_file.attached?
  end

  # ========================================================================
  # HELPERS DE VALIDACIÓN
  # Quién validó, por qué flujo, para mostrar en vistas y auditoría
  # ========================================================================

  # ¿Quién es el responsable final? (priorizar revisión humana)
  def validator
    validation_user || validated_by
  end

  def human_validated?
    validation_user.present?
  end

  def auto_validated_only?
    auto_validated? && validation_user.nil?
  end

  def validator_name
    if validation_user.present?
      "#{validation_user.name} (revisión manual)"
    elsif validated_by.present?
      validated_by.name
    elsif auto_validated?
      "Validación automática (OCR)"
    else
      "Sin validar"
    end
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

  # Validación HUMANA — Admin/Superadmin aprueba el documento
  def mark_as_validated!(user, notes: nil)
    update!(
      document_status: DocumentStatus.find_by(name: 'validado_vigente'),
      validated_by: user,
      validation_user: user,
      validated_at: Time.current,
      validation_notes: notes
    )
  end

  # Validación AUTOMÁTICA — OCR/AI aprueba sin intervención humana
  def mark_as_auto_validated!(analysis_result = nil)
    update!(
      document_status: DocumentStatus.find_by(name: 'validado_vigente'),
      validated_at: Time.current,
      auto_validated: true,
      analysis_result: analysis_result
    )
    # validated_by y validation_user quedan nil intencionalmente
    # Esto permite que un admin revise después si lo requiere
  end

  # Rechazo — Siempre humano, crea review para auditoría
  def reject!(reason, user)
    document_reviews.create!(
      user: user,
      action: 'rechazado',
      notes: reason
    )

    update!(
      document_status: DocumentStatus.find_by(name: 'rechazado'),
      validated_by: user,
      validation_user: user,
      validated_at: Time.current,
      validation_notes: reason
    )
  end

  # ========================================================================
  # MÉTODOS DE VISUALIZACIÓN
  # ========================================================================

  def status_badge_class
    return 'bg-secondary' unless uploaded?

    case document_status&.name
    when 'validado_vigente' then 'bg-success'
    when 'rechazado' then 'bg-danger'
    when 'vencido' then 'bg-dark'
    when 'pendiente_solicitud' then 'bg-warning'
    when 'recibido_revision' then 'bg-info'
    when 'solicitado_cliente' then 'bg-info'
    when 'observaciones' then 'bg-warning'
    else 'bg-secondary'
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
    return unless uploaded?

    Rails.application.routes.url_helpers.rails_blob_path(
      document_file,
      disposition: 'attachment'
    )
  end

  def can_reupload?
    document_status&.name.in?(['rechazado', 'expirado']) || submitted_at.blank?
  end

  # ========================================================================
  # NOTAS Y REVIEWS
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
  # PRIVADOS
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
  end

  def notify_status_change
    # DocumentStatusNotificationJob.perform_later(self.id)
  end
end
