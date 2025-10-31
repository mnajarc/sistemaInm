class ContractSignerType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :display_name, presence: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :display_name) }
  scope :requiring_power, -> { where(requires_power_of_attorney: true) }
  
  def to_s
    display_name
  end
  
  def needs_power_of_attorney?
    requires_power_of_attorney?
  end
end
