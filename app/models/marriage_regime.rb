# app/models/marriage_regime.rb
class MarriageRegime < ApplicationRecord
    include AutoSluggable
    validates :name, :display_name, presence: true, uniqueness: true
    
    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:sort_order) }
  end
  
  