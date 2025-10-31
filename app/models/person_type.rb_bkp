class PersonType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  
  def to_s
    display_name
  end
  
  def persona_fisica?
    name == 'PF'
  end
  
  def persona_moral?
    name == 'PM'
  end
  
  def fideicomiso?
    name == 'FIDE'
  end
end
