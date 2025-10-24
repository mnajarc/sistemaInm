# app/models/document_review.rb
class DocumentReview < ApplicationRecord
  # ========================================================================
  # RELACIONES
  # ========================================================================
  
  belongs_to :document_submission
  belongs_to :user
  
  # ========================================================================
  # VALIDACIONES
  # ========================================================================
  
  validates :action, presence: true, inclusion: { 
    in: %w[validado rechazado solicitado_correccion revisado aprobado observado]
  }
  
  validates :reviewed_at, presence: true
  validates :notes, presence: true, if: -> { action == 'rechazado' }
  
  # ========================================================================
  # SCOPES
  # ========================================================================
  
  scope :recent, -> { order(reviewed_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :approved, -> { where(action: 'validado') }
  scope :rejected, -> { where(action: 'rechazado') }
  scope :pending_correction, -> { where(action: 'solicitado_correccion') }
  
  scope :by_reviewer, ->(user) { where(user: user) }
  scope :in_date_range, ->(start_date, end_date) { 
    where(reviewed_at: start_date..end_date) 
  }
  
  # ========================================================================
  # CALLBACKS
  # ========================================================================
  
  before_validation :set_reviewed_at, on: :create
  after_create :notify_submission_owner, if: -> { should_notify? }
  
  # ========================================================================
  # MÉTODOS DE INSTANCIA
  # ========================================================================
  
  def approved?
    action == 'validado'
  end
  
  def rejected?
    action == 'rechazado'
  end
  
  def needs_correction?
    action == 'solicitado_correccion'
  end
  
  def reviewer_name
    user.email
  end
  
  def action_display
    {
      'validado' => 'Validado',
      'rechazado' => 'Rechazado',
      'solicitado_correccion' => 'Solicitud de Corrección',
      'revisado' => 'Revisado',
      'aprobado' => 'Aprobado',
      'observado' => 'Observado'
    }[action] || action.titleize
  end
  
  def badge_class
    case action
    when 'validado', 'aprobado' then 'bg-success'
    when 'rechazado' then 'bg-danger'
    when 'solicitado_correccion', 'observado' then 'bg-warning'
    when 'revisado' then 'bg-info'
    else 'bg-secondary'
    end
  end
  
  # ========================================================================
  # MÉTODOS PRIVADOS
  # ========================================================================
  
  private
  
  def set_reviewed_at
    self.reviewed_at ||= Time.current
  end
  
  def should_notify?
    # Notificar solo en acciones críticas
    %w[validado rechazado solicitado_correccion].include?(action)
  end
  
  def notify_submission_owner
    # TODO: Implementar notificación (email, Turbo Stream, etc.)
    # DocumentReviewNotificationJob.perform_later(id)
  end
end
