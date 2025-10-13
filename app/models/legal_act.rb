class LegalAct < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  validates :category, presence: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  scope :by_category, ->(category) { where(category: category) }
  
  def to_s
    display_name
  end
  
  def oneroso?
    category == 'Oneroso'
  end
  
  def gratuito?
    category == 'Gratuito'
  end
end
