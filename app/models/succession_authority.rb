# app/models/succession_authority.rb
class SuccessionAuthority < ApplicationRecord
  # Validaciones
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  scope :judicial, -> { where(category: 'judicial') }
  scope :notarial, -> { where(category: 'notarial') }
  
  # Métodos
  def to_s
    display_name
  end
end
