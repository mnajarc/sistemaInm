class PropertyExclusivity < ApplicationRecord
  belongs_to :property
  belongs_to :agent
  
  validates :start_date, presence: true
  validates :commission_percentage, presence: true, 
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :is_active, inclusion: { in: [true, false] }
  
  scope :active, -> { where(is_active: true) }
  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  scope :expired, -> { where('end_date < ?', Date.current) }
  
  validate :end_date_after_start_date
  validate :no_overlapping_exclusivities
  
  def current?
    is_active && start_date <= Date.current && (end_date.nil? || end_date >= Date.current)
  end
  
  def expired?
    end_date && end_date < Date.current
  end
  
  def duration_in_days
    return nil unless start_date && end_date
    (end_date - start_date).to_i
  end
  
  def agent_name
    agent&.user&.email || "Agente ##{agent_id}"
  end
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, 'debe ser posterior a la fecha de inicio') if end_date <= start_date
  end
  
  def no_overlapping_exclusivities
    return unless property_id && start_date
    
    overlapping = PropertyExclusivity.where(property: property, is_active: true)
                                   .where.not(id: id)
    
    overlapping.each do |other|
      if dates_overlap?(other)
        errors.add(:start_date, 'se superpone con otra exclusividad activa')
        break
      end
    end
  end
  
  def dates_overlap?(other)
    start_date <= (other.end_date || Date::Infinity.new) &&
    (end_date || Date::Infinity.new) >= other.start_date
  end

  def end_after_start
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "debe ser posterior a la fecha de inicio") if end_date <= start_date
  end
end