class PropertyExclusivity < ApplicationRecord
  belongs_to :property
  belongs_to :agent

  validates :start_date, :end_date, :commission_percentage, presence: true
  validate  :end_after_start
  validates :commission_percentage, numericality: { in: 0..100 }

  scope :active, -> { where(is_active: true) }

  private

  def end_after_start
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "debe ser posterior a la fecha de inicio") if end_date <= start_date
  end
end
