class DocumentValidityRule < ApplicationRecord
  belongs_to :document_type

  # Validaciones Rails + DB
  validates :validity_period_months, presence: true, 
            numericality: { only_integer: true, greater_than: 0 },
            db_numericality: { only_integer: true, greater_than: 0 }
  validates :valid_from, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validate  :valid_until_after_valid_from

  scope :current, -> {
    where(is_active: true)
      .where('valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)', Date.current, Date.current)
  }

  def self.for(document_type)
    current.find_by(document_type: document_type)
  end

  private

  def valid_until_after_valid_from
    return if valid_until.blank? || valid_from.blank?
    errors.add(:valid_until, 'debe ser posterior a valid_from') if valid_until < valid_from
  end
end
