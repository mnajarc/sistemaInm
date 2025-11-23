# app/models/succession_type.rb
class SuccessionType < ApplicationRecord
  # Validaciones
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  scope :judicial, -> { where(requires_judicial: true) }
  scope :notarial, -> { where(requires_judicial: false) }
  
  # Métodos
  def to_s
    display_name
  end
end
