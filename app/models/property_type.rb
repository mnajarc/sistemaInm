class PropertyType < ApplicationRecord
  has_many :properties, dependent: :restrict_with_error
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_order, -> { order(:sort_order) }
  
  def to_s
    display_name
  end
end

