class FinancialInstitution < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :name) }
  scope :banks, -> { where(institution_type: 'Banco') }
  
  def to_s
    short_name.present? ? short_name : name
  end
  
  def display_name
    short_name.present? ? "#{short_name} (#{name})" : name
  end
end
