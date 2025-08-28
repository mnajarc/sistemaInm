class DocumentRequirement < ApplicationRecord
  belongs_to :document_type

  # Validaciones Rails + DB
  validates :property_type, presence: true
  validates :transaction_type, presence: true
  validates :client_type, presence: true
  validates :person_type, presence: true
  validates :valid_from, presence: true
  validates :is_required, inclusion: { in: [true, false] }
  validate  :valid_until_after_valid_from

  scope :applicable, ->(date = Date.current) {
    where('valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)', date, date)
  }

  private

  def valid_until_after_valid_from
    return if valid_until.blank? || valid_from.blank?
    errors.add(:valid_until, 'debe ser posterior a valid_from') if valid_until < valid_from
  end
end
