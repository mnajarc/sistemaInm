class BusinessStatus < ApplicationRecord
  include CatalogConfigurable
  
  has_many :business_transactions, dependent: :restrict_with_error
  
  validates :color, presence: true
  validates :minimum_role_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :visible_for_role, ->(role) { 
    where('minimum_role_level >= ?', role&.level || 999) 
  }
  
  # Estados específicos configurables
  def self.available_status
    find_by(name: SystemConfiguration.get('business.available_status_name', 'available'))
  end
  
  def self.reserved_status  
    find_by(name: SystemConfiguration.get('business.reserved_status_name', 'reserved'))
  end
  
  def self.active_statuses
    where(name: SystemConfiguration.get('business.active_statuses', ['available', 'reserved']))
  end
  
  def self.completed_statuses
    where(name: SystemConfiguration.get('business.completed_statuses', ['sold', 'rented']))
  end
  
  # Configuraciones específicas del estado
  def allows_modifications?
    metadata_for('allows_modifications', true)
  end
  
  def requires_documentation?
    metadata_for('requires_documentation', false)
  end
  
  def auto_notify_agents?
    metadata_for('auto_notify_agents', false)
  end
  
  def completion_percentage
    metadata_for('completion_percentage', 0)
  end
end
