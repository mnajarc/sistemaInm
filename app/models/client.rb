# app/models/client.rb
class Client < ApplicationRecord
  belongs_to :user, optional: true  # user_id puede ser NULL en BD
  has_many :offered_transactions, class_name: 'BusinessTransaction', foreign_key: 'offering_client_id'
  has_many :acquired_transactions, class_name: 'BusinessTransaction', foreign_key: 'acquiring_client_id'
  has_many :contracts
  has_many :transaction_co_owners, class_name: 'BusinessTransactionCoOwner'
 
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
end
