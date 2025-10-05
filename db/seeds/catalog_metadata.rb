puts "🏗️ Configurando metadatos de catálogos..."

# Metadatos para BusinessStatus
business_status_metadata = {
  'available' => {
    allows_modifications: true,
    requires_documentation: false,
    auto_notify_agents: true,
    completion_percentage: 0,
    next_possible_statuses: ['reserved', 'cancelled']
  },
  'reserved' => {
    allows_modifications: true,
    requires_documentation: true,
    auto_notify_agents: true, 
    completion_percentage: 50,
    next_possible_statuses: ['sold', 'rented', 'available', 'cancelled']
  },
  'sold' => {
    allows_modifications: false,
    requires_documentation: true,
    auto_notify_agents: false,
    completion_percentage: 100,
    next_possible_statuses: []
  },
  'rented' => {
    allows_modifications: false,
    requires_documentation: true,
    auto_notify_agents: false,
    completion_percentage: 100,
    next_possible_statuses: []
  },
  'cancelled' => {
    allows_modifications: false,
    requires_documentation: true,
    auto_notify_agents: true,
    completion_percentage: 0,
    next_possible_statuses: ['available']
  }
}

BusinessStatus.all.each do |status|
  if business_status_metadata[status.name]
    status.metadata = business_status_metadata[status.name]
    status.save!
  end
end

# Metadatos para OperationType
operation_type_metadata = {
  'sale' => {
    requires_down_payment: true,
    default_commission_percentage: 3.0,
    max_duration_months: nil,
    requires_guarantor: false,
    allows_co_ownership: true,
    required_document_categories: ['legal', 'financial', 'identity'],
    default_contract_type: 'purchase_agreement'
  },
  'rent' => {
    requires_down_payment: true,
    default_commission_percentage: 1.0,
    max_duration_months: 24,
    requires_guarantor: true,
    allows_co_ownership: false,
    required_document_categories: ['identity', 'financial', 'references'],
    default_contract_type: 'rental_agreement'
  },
  'short_rent' => {
    requires_down_payment: false,
    default_commission_percentage: 0.5,
    max_duration_months: 6,
    requires_guarantor: false,
    allows_co_ownership: false,
    required_document_categories: ['identity'],
    default_contract_type: 'temporary_rental'
  }
}

OperationType.all.each do |operation|
  if operation_type_metadata[operation.name]
    operation.metadata = operation_type_metadata[operation.name]
    operation.save!
  end
end

# Metadatos para PropertyType
property_type_metadata = {
  'house' => {
    default_built_area_min: 50.0,
    default_built_area_max: 1000.0,
    requires_parking: true,
    allows_pets_by_default: true,
    standard_amenities: ['garden', 'terrace', 'parking'],
    required_fields: ['bedrooms', 'bathrooms', 'lot_area_m2'],
    validation_rules: {
      bedrooms: { min: 1, max: 10 },
      bathrooms: { min: 1, max: 8 }
    }
  },
  'apartment' => {
    default_built_area_min: 30.0,
    default_built_area_max: 300.0,
    requires_parking: false,
    allows_pets_by_default: false,
    standard_amenities: ['elevator', 'balcony'],
    required_fields: ['bedrooms', 'bathrooms'],
    validation_rules: {
      bedrooms: { min: 1, max: 5 },
      bathrooms: { min: 1, max: 4 }
    }
  },
  'commercial' => {
    default_built_area_min: 20.0,
    default_built_area_max: 5000.0,
    requires_parking: true,
    allows_pets_by_default: false,
    standard_amenities: ['security', 'access_control'],
    required_fields: ['built_area_m2', 'parking_spaces'],
    validation_rules: {
      parking_spaces: { min: 1, max: 50 }
    }
  }
}

PropertyType.all.each do |property_type|
  if property_type_metadata[property_type.name]
    property_type.metadata = property_type_metadata[property_type.name]
    property_type.save!
  end
end

# Metadatos para CoOwnershipType  
co_ownership_metadata = {
  'single_owner' => {
    min_co_owners: 1,
    max_co_owners: 1,
    allows_inheritance_cases: false,
    requires_legal_documentation: false,
    default_percentage_distribution: 'single',
    requires_notarization: false
  },
  'joint_ownership' => {
    min_co_owners: 2,
    max_co_owners: 4,
    allows_inheritance_cases: false,
    requires_legal_documentation: true,
    default_percentage_distribution: 'equal',
    requires_notarization: true
  },
  'inheritance' => {
    min_co_owners: 1,
    max_co_owners: nil,
    allows_inheritance_cases: true,
    requires_legal_documentation: true,
    default_percentage_distribution: 'custom',
    requires_notarization: true
  },
  'trust' => {
    min_co_owners: 2,
    max_co_owners: 10,
    allows_inheritance_cases: false,
    requires_legal_documentation: true,
    default_percentage_distribution: 'custom',
    requires_notarization: true
  }
}

CoOwnershipType.all.each do |ownership_type|
  if co_ownership_metadata[ownership_type.name]
    ownership_type.metadata = co_ownership_metadata[ownership_type.name]
    ownership_type.save!
  end
end

puts "✅ Metadatos de catálogos configurados exitosamente"