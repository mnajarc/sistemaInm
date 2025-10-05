class OperationType < ApplicationRecord
  include CatalogConfigurable
  
  has_many :business_transactions, dependent: :restrict_with_error
  has_many :document_requirements, dependent: :destroy
  
  validates :color, presence: true
  
  # Tipos específicos configurables
  def self.sale_types
    where(name: SystemConfiguration.get('operation.sale_type_names', ['sale']))
  end
  
  def self.rent_types
    where(name: SystemConfiguration.get('operation.rent_type_names', ['rent', 'short_rent']))
  end
  
  def self.commercial_types
    where(name: SystemConfiguration.get('operation.commercial_type_names', ['commercial_sale', 'commercial_rent']))
  end
  
  # Configuraciones específicas del tipo de operación
  def requires_down_payment?
    metadata_for('requires_down_payment', false)
  end
  
  def default_commission_percentage
    metadata_for('default_commission_percentage', 0.0).to_f
  end
  
  def max_duration_months
    metadata_for('max_duration_months', nil)&.to_i
  end
  
  def requires_guarantor?
    metadata_for('requires_guarantor', false)
  end
  
  def allows_co_ownership?
    metadata_for('allows_co_ownership', true)
  end
  
  def required_document_categories
    metadata_for('required_document_categories', [])
  end
end
