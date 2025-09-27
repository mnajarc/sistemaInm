class Agent < ApplicationRecord
  belongs_to :user  # user_id es requerido (NOT NULL en BD)
  has_many :commissions
  has_many :property_exclusivities
  has_many :properties, through: :property_exclusivities
  has_many :from_agent_transfers, class_name: 'AgentTransfer', foreign_key: 'from_agent_id'
  has_many :to_agent_transfers, class_name: 'AgentTransfer', foreign_key: 'to_agent_id'
  has_many :listing_transactions, class_name: 'BusinessTransaction', foreign_key: 'listing_agent_id'
  has_many :current_transactions, class_name: 'BusinessTransaction', foreign_key: 'current_agent_id'
  has_many :selling_transactions, class_name: 'BusinessTransaction', foreign_key: 'selling_agent_id'

  validates :license_number, uniqueness: true, allow_blank: true
  validates :commission_rate, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :is_active, inclusion: { in: [true, false] }

  scope :active, -> { where(is_active: true) }
  scope :with_license, -> { where.not(license_number: nil) }

  def total_commissions
    commissions.where(status: 'paid').sum(:amount)
  end

  def active_exclusivities
    property_exclusivities.where(is_active: true)
  end

  def all_transactions
    BusinessTransaction.where(
      'listing_agent_id = ? OR current_agent_id = ? OR selling_agent_id = ?',
      user_id, user_id, user_id
    )
  end

  def specialties_list
    return [] if specialties.blank?
    specialties.split(',').map(&:strip)
  end

  def display_name
    user.email
  end

  def active?
    is_active == true
  end
end
