# app/models/operation_type.rb
class OperationType < ApplicationRecord
  include AutoSluggable
  
  has_many :business_transactions
  has_many :properties, through: :business_transactions
  
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

  def active_transactions_count
    business_transactions.active.count
  end

  # CORREGIDO

  def active_properties_count
    Property.joins(business_transactions: :business_status)
            .where(
              business_transactions: { operation_type_id: id },
              business_statuses: { active: true }
            )
            .distinct
            .count
  end
end
