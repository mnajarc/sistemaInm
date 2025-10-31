class IdentificationType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  
  def to_s
    display_name
  end
  
  def expires?
    validity_years.present? && validity_years < 999
  end
end
