class PropertyType < ApplicationRecord
  include CatalogConfigurable
  
  has_many :properties, dependent: :restrict_with_error
  has_many :document_requirements, dependent: :destroy
  
  # Configuraciones específicas del tipo de propiedad
  def default_built_area_min
    metadata_for('default_built_area_min', 0).to_f
  end
  
  def default_built_area_max
    metadata_for('default_built_area_max', 10000).to_f
  end
  
  def requires_parking?
    metadata_for('requires_parking', false)
  end
  
  def allows_pets_by_default?
    metadata_for('allows_pets_by_default', true)
  end
  
  def standard_amenities
    metadata_for('standard_amenities', [])
  end
  
  def property_fields_config
    metadata_for('property_fields_config', {})
  end
  
  def validation_rules
    metadata_for('validation_rules', {})
  end
  
  # Campos requeridos según tipo
  def required_fields
    base_fields = %w[title description price address city state postal_code]
    additional_fields = metadata_for('required_fields', [])
    (base_fields + additional_fields).uniq
  end
  
  def optional_fields
    metadata_for('optional_fields', [])
  end
end
