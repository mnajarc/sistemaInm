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
  belongs_to :uploaded_by, class_name: 'User', optional: true
  belongs_to :business_transaction_co_owner, optional: true
  belongs_to :validation_user, class_name: 'User', optional: true, foreign_key: 'validation_user_id'
  

  has_many :document_notes, dependent: :destroy

  # Active Storage
  has_one_attached :document_file do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :medium, resize_to_limit: [800, 800]
  end
  
  has_many :document_reviews, dependent: :destroy
  
  # ========================================================================
  # VALIDACIONES
  # ========================================================================
  
  validates :party_type, presence: true, inclusion: { 
    in: %w[oferente adquiriente copropietario copropietario_principal]
  }
  
  # Validación de Active Storage - sintaxis Rails 8
  validate :validate_document_file_type
  validate :validate_document_file_size
  
  validates :business_transaction_co_owner_id, 
    presence: true, 
    if: -> { party_type == 'copropietario' }
  
  validates :analysis_status, 
    inclusion: { in: %w[pending processing completed failed] },
    allow_nil: true
  
  validates :validation_status, presence: true, inclusion: {
    in: %w[pending_review approved rejected expired]
  }



  
  # ========================================================================
  # SCOPES
  # ========================================================================
  
  scope :for_oferente, -> { where(party_type: 'oferente') }
  scope :for_adquiriente, -> { where(party_type: 'adquiriente') }
  scope :for_copropietario, -> { where(party_type: 'copropietario') }
  scope :for_co_owner, ->(co_owner) { where(business_transaction_co_owner: co_owner) }
  
  scope :pending, -> { 
    joins(:document_status).where(document_statuses: { name: 'pendiente_solicitud' }) 
  }
  scope :completed, -> { 
    joins(:document_status).where(document_statuses: { name: 'validado_vigente' }) 
  }
  scope :validated, -> { 
    joins(:document_status).where(document_statuses: { name: 'validado' }) 
  }
  scope :rejected, -> { 
    joins(:document_status).where(document_statuses: { name: 'rechazado' }) 
  }
  
  scope :expiring_soon, -> { 
    where('expiry_date <= ? AND expiry_date > ?', 30.days.from_now, Date.current) 
  }
  scope :expired, -> { where('expiry_date < ?', Date.current) }
  
  scope :pending_upload, -> { where(submitted_at: nil) }
  scope :uploaded, -> { where.not(submitted_at: nil) }
  
  scope :pending_analysis, -> { where(analysis_status: 'pending') }
  scope :analyzed, -> { where(analysis_status: 'completed') }
  scope :auto_validated, -> { where(auto_validated: true) }
  
  # ========================================================================
  # CALLBACKS
  # ========================================================================
  
  after_create_commit :schedule_analysis, if: :document_file_attached?
  
  # app/models/document_submission.rb
  # (Agregar después de la línea has_many :document_reviews)

  # Métodos para reviews
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

  # ========================================================================
  # MÉTODOS DE ESTADO
  # ========================================================================
  
  def pending?
    document_status&.name == 'pendiente_solicitud'
  end
  
  def completed?
    document_status&.name == 'validado_vigente'
  end
  
  def uploaded?
    # document_file.attached? && submitted_at.present?
    submitted_at.present?
  end
  
  def analyzed?
    analysis_status == 'completed'
  end
  
  def pending_validation?
    uploaded? && document_status&.name == 'pendiente_validacion'
  end
  
  def expired?
    expiry_date.present? && expiry_date < Date.current
  end
  
  def expiring_soon?
    expiry_date.present? && expiry_date <= 30.days.from_now && !expired?
  end
  
  def has_files?
    document_file.attached?
  end
  
  def legibility_status
    return 'unknown' if legibility_score.nil?
    
    case legibility_score
    when 0...40 then 'poor'
    when 40...70 then 'fair'
    when 70...90 then 'good'
    else 'excellent'
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
      validation_notes: notes
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
      validation_notes: reason
    )
  end
  
  # ========================================================================
  # MÉTODOS AUXILIARES
  # ========================================================================
  
  def status_badge_class
    return 'bg-secondary' unless uploaded?
    
    case document_status&.name
    when 'validado' then 'bg-success'
    when 'validado_vigente' then 'bg-success'
    when 'rechazado' then 'bg-danger'
    when 'pendiente_validacion' then 'bg-warning'
    when 'vencido' then 'bg-dark'
    when 'recibido_revision' then 'bg-info'
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
    when 'copropietario'
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

  def is_expired?
    return false unless expiry_date.present?
    Date.current > expiry_date
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
end
