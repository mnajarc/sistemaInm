# app/models/business_status.rb
class BusinessStatus < ApplicationRecord
     include AutoSluggable
  has_many :business_transactions
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :color, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_sort_order, -> { order(:sort_order) }
  
  def color_class
    "badge-#{color}"
  end
  
  def transactions_count
    business_transactions.count
  end
  
  def to_s
    display_name
  end
end