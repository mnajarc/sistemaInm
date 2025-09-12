class OperationType < ApplicationRecord
  has_many :business_transactions, dependent: :restrict_with_error
  has_many :properties, through: :business_transactions
   
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_order, -> { order(:sort_order) }
  
  def to_s
    display_name
  end
    
  # Método para contar transacciones activas
  def active_transactions_count
    business_transactions.active.count
  end
  
  # Método para contar propiedades únicas con transacciones activas
  def active_properties_count
    properties.joins(:business_transactions)
              .merge(business_transactions.active)
              .distinct.count
  end

end

