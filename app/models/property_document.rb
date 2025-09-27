class PropertyDocument < ApplicationRecord
  belongs_to :property
  belongs_to :document_type
  belongs_to :user

  # Validaciones Rails + DB
  validates :status, presence: true
  validates :uploaded_at, presence: true
  validates :issued_at, presence: true
  validate  :not_expired, if: -> { expires_at.present? }

  before_validation :calculate_expiry_date, on: :create

  private

  def calculate_expiry_date
    rule = DocumentValidityRule.for(document_type)
    return unless rule && issued_at

    self.expires_at = issued_at + rule.validity_period_months.months
  end

  def not_expired
    errors.add(:issued_at, "está expirado") if expires_at < Date.current
  end
end
