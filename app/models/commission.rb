class Commission < ApplicationRecord
  belongs_to :property
  belongs_to :agent

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :commission_type, presence: true
  validates :status, presence: true

  scope :paid, -> { where(status: 'paid') }
  scope :pending, -> { where(status: 'pending') }
  scope :by_agent, ->(agent) { where(agent: agent) }
  scope :by_property, ->(property) { where(property: property) }
  scope :by_status, ->(status) { where(status: status) }

  def paid?
    status == 'paid' && paid_at.present?
  end

  def pending?
    status == 'pending'
  end

  def overdue?
    status == 'pending' && created_at < 30.days.ago
  end

  def mark_as_paid!
    update!(status: 'paid', paid_at: Time.current)
  end

  def mark_as_pending!
    update!(status: 'pending', paid_at: nil)
  end

  def agent_name
    agent&.user&.email || "Agente ##{agent_id}"
  end

  def property_title
    property&.title || "Propiedad ##{property_id}"
  end

  def display_amount
    "$#{amount.to_f.round(2)}"
  end

  def commission_percentage
    return 0 if property&.price.blank? || property.price <= 0
    (amount / property.price * 100).round(2)
  end
end
