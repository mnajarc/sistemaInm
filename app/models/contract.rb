class Contract < ApplicationRecord
  belongs_to :client
  belongs_to :property

  validates :start_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where(status: 'expired') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :by_status, ->(status) { where(status: status) }
  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  scope :by_date_range, ->(start_date, end_date) { where(start_date: start_date..end_date) }

  validate :end_date_after_start_date
  validate :reasonable_contract_amount

  def active?
    status == 'active'
  end

  def expired?
    end_date && end_date < Date.current
  end

  def current?
    active? && start_date <= Date.current && (end_date.nil? || end_date >= Date.current)
  end

  def cancelled?
    status == 'cancelled'
  end

  def duration_in_days
    return nil unless start_date && end_date
    (end_date - start_date).to_i
  end

  def duration_in_months
    return nil unless duration_in_days
    (duration_in_days / 30.0).round(1)
  end

  def days_remaining
    return nil unless end_date
    (end_date - Date.current).to_i
  end

  def monthly_amount
    return amount unless duration_in_months && duration_in_months > 0
    (amount / duration_in_months).round(2)
  end

  def display_amount
    "$#{amount.to_f.round(2)}"
  end

  def display_status
    status.humanize
  end

  def client_name
    client&.name || "Cliente ##{client_id}"
  end

  def property_title
    property&.title || "Propiedad ##{property_id}"
  end

  def contract_summary
    "#{client_name} - #{property_title} (#{display_amount})"
  end

  def activate!
    update!(status: 'active')
  end

  def cancel!(reason = nil)
    update!(status: 'cancelled')
  end

  def mark_as_expired!
    update!(status: 'expired')
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'debe ser posterior a la fecha de inicio') if end_date <= start_date
  end

  def reasonable_contract_amount
    return unless amount
    errors.add(:amount, 'debe ser mayor a cero') if amount < 0
    errors.add(:amount, 'parece demasiado alto, verifique') if amount > 999_999_999
  end
end
