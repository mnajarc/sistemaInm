class CoOwnershipRole < ApplicationRecord
     include AutoSluggable
  has_many :business_transaction_co_owners, 
           foreign_key: 'role_name', 
           primary_key: 'name'

  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :by_sort_order, -> { order(:sort_order, :display_name) }

  def to_s
    display_name
  end

  def usage_count
    business_transaction_co_owners.count
  end
end