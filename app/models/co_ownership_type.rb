class CoOwnershipType < ApplicationRecord
  include CatalogConfigurable
  
  has_many :properties, dependent: :nullify
  has_many :business_transaction_co_owners, dependent: :destroy
  
  validates :minimum_role_level, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :visible_for_level, ->(level) { where('minimum_role_level >= ?', level || 999) }
  
  # Configuraciones específicas de copropiedad
  def min_co_owners
    metadata_for('min_co_owners', 1).to_i
  end
  
  def max_co_owners
    metadata_for('max_co_owners', nil)&.to_i
  end
  
  def allows_inheritance_cases?
    metadata_for('allows_inheritance_cases', false)
  end
  
  def requires_legal_documentation?
    metadata_for('requires_legal_documentation', true)
  end
  
  def default_percentage_distribution
    metadata_for('default_percentage_distribution', 'equal') # 'equal', 'custom', 'majority_minority'
  end
  
  def requires_notarization?
    metadata_for('requires_notarization', true)
  end
  
  # Validaciones automáticas basadas en configuración
  def validate_co_owners_count(co_owners_count)
    errors = []
    
    if co_owners_count < min_co_owners
      errors << "Debe tener al menos #{min_co_owners} copropietarios"
    end
    
    if max_co_owners && co_owners_count > max_co_owners
      errors << "No puede tener más de #{max_co_owners} copropietarios"
    end
    
    errors
  end
end
