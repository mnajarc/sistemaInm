# app/models/property_type.rb
class PropertyType < ApplicationRecord
     include AutoSluggable
  has_many :properties
  
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :sort_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :by_sort_order, -> { order(:sort_order) }
  
  def properties_count
    properties.count
  end
  
  def active_properties_count
    properties.joins(:user).where(users: { active: true }).count
  end
  
  def to_s
    display_name
  end
end