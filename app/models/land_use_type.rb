class LandUseType < ApplicationRecord
    belongs_to :parent, class_name: 'LandUseType', optional: true
    has_many :subcategories, class_name: 'LandUseType', foreign_key: :parent_id
    has_many :properties
    
    validates :name, :code, :category, presence: true
    validates :code, uniqueness: true
    
    scope :active, -> { where(active: true) }
    scope :main_categories, -> { where(parent_id: nil) }
    scope :ordered, -> { order(:sort_order, :name) }
    scope :residential, -> { where(category: 'residential') }
    scope :commercial, -> { where(category: 'commercial') }
    scope :mixed, -> { where(category: 'mixed') }
    
    def display_name
      parent ? "#{parent.name} - #{name}" : name
    end
  end
  
  