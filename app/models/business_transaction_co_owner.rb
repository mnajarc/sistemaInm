class BusinessTransactionCoOwner < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :client, optional: true
  belongs_to :co_ownership_role, foreign_key: 'role', primary_key: 'name', optional: true

  # validates :business_transaction_id, presence: true
  # validates :percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :person_name, presence: true, if: -> { client_id.blank? }
  validates :role, presence: true

  scope :active, -> { where(active: true) }

  def is_primary?
    percentage == 100 || role == 'propietario' || role == 'vendedor'
  end

  def display_name
    client&.display_name || person_name || "Sin nombre"
  end

  def display_info
    "#{display_name} (#{percentage}%)"
  end
end
