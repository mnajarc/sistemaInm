class MexicanState < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, length: { maximum: 5 }
  validates :full_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }
  
  def to_s
    display_name
  end
  
  def display_name
    name
  end
end
