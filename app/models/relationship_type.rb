# app/models/relationship_type.rb
class RelationshipType < ApplicationRecord
  # Validaciones
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  scope :by_category, ->(category) { where(category: category) }
  
  # Métodos
  def to_s
    display_name
  end
end
