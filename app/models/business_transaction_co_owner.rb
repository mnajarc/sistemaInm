class BusinessTransactionCoOwner < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :client, optional: true
  belongs_to :co_ownership_role, foreign_key: 'role', primary_key: 'name', optional: true

  validates :person_name, presence: true, if: -> { client_id.blank? }
  validates :percentage, presence: true, numericality: { 
    greater_than: 0, 
    less_than_or_equal_to: 100 
  }
  validates :role, presence: true

  scope :active, -> { where(active: true) }
  scope :deceased, -> { where(deceased: true) }
  scope :alive, -> { where(deceased: false) }
  scope :by_role, ->(role) { where(role: role) }

  def display_name
    client&.name || person_name
  end

  def display_info
    info = display_name
    info += " (#{percentage}%)"
    info += " - FINADO" if deceased?
    info += " - #{role.upcase}" if role.present?
    info
  end

  def role_display_name
    co_ownership_role&.display_name || role&.humanize || 'Sin especificar'
  end

  def deceased?
    deceased == true
  end

  def alive?
    !deceased?
  end
end
