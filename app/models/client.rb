class Client < ApplicationRecord
  belongs_to :user, optional: true
  has_many :offered_transactions, class_name: 'BusinessTransaction', foreign_key: 'offering_client_id'
  has_many :acquired_transactions, class_name: 'BusinessTransaction', foreign_key: 'acquiring_client_id'
  has_many :contracts
  has_many :transaction_co_owners, class_name: 'BusinessTransactionCoOwner'
  
  # ✅ NUEVAS RELACIONES PARA OFERTAS
  has_many :offers_made, class_name: 'Offer', foreign_key: 'offerer_id'
  has_many :active_offers, -> { active }, class_name: 'Offer', foreign_key: 'offerer_id'
  has_many :pending_offers, -> { joins(:offer_status).where(offer_statuses: { name: 'pending' }) }, 
           class_name: 'Offer', foreign_key: 'offerer_id'

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
  scope :with_system_user, -> { where.not(user_id: nil) }
  scope :external_only, -> { where(user_id: nil) }

  def all_transactions
    BusinessTransaction.where(
      'offering_client_id = ? OR acquiring_client_id = ?', id, id
    )
  end

  def has_system_access?
    user_id.present?
  end

  def full_contact_info
    [name, email, phone].compact.join(' - ')
  end

  def display_name
    name.presence || email.presence || "Cliente ##{id}"
  end

  # ✅ NUEVOS MÉTODOS PARA OFERTAS
  def offers_summary
    {
      total: offers_made.count,
      active: active_offers.count,
      pending: pending_offers.count,
      in_evaluation: offers_made.in_evaluation_status.count
    }
  end

  def has_active_offers?
    active_offers.exists?
  end

  def can_make_offer_on?(business_transaction)
    # No puede ofertar si ya tiene una oferta activa en esa transacción
    !offers_made.active.where(business_transaction: business_transaction).exists?
  end
end
