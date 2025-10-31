 # app/models/operation_type.rb
class OperationType < ApplicationRecord
     include AutoSluggable
  has_many :business_transactions
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_sort_order, -> { order(:sort_order) }
  
  def transactions_count
    business_transactions.count
  end
  
  def sale?
    name == 'sale'
  end
  
  def rent?
    %w[rent short_rent].include?(name)
  end
  
  def to_s
    display_name
  end

  def self.rents
    where(name: ['rent', 'short_rent'])
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
