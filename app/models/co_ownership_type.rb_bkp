class CoOwnershipType < ApplicationRecord
  # Relación con propiedades (si aplica)
  has_many :properties, dependent: :nullify
  has_many :business_transaction_co_owners, dependent: :destroy

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_sort_order, -> { order(:sort_order) }
  scope :visible_for_level, ->(level) { where("minimum_role_level >= ?", level) }

  # Validaciones
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :sort_order, presence: true
  validates :minimum_role_level, presence: true
end
