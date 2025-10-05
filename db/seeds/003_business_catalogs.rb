puts "📊 Creando catálogos de negocio..."

# BusinessStatuses con configuración dinámica
default_color = SystemConfiguration.get('ui.default_catalog_color', 'secondary')

business_statuses_data = [
  { 
    name: 'available', 
    display_name: 'Disponible', 
    color: 'success', 
    sort_order: 10,
    minimum_role_level: agent_level,
    metadata: {
      allows_modifications: true,
      requires_documentation: false,
      auto_notify_agents: true,
      completion_percentage: 0
    }
  },
  { 
    name: 'reserved', 
    display_name: 'Reservado', 
    color: 'warning', 
    sort_order: 20,
    minimum_role_level: agent_level,
    metadata: {
      allows_modifications: true,
      requires_documentation: true,
      auto_notify_agents: true,
      completion_percentage: 50
    }
  },
  { 
    name: 'sold', 
    display_name: 'Vendido', 
    color: 'info', 
    sort_order: 30,
    minimum_role_level: agent_level,
    metadata: {
      allows_modifications: false,
      requires_documentation: true,
      auto_notify_agents: false,
      completion_percentage: 100
    }
  },
  { 
    name: 'rented', 
    display_name: 'Alquilado', 
    color: 'primary', 
    sort_order: 40,
    minimum_role_level: agent_level,
    metadata: {
      allows_modifications: false,
      requires_documentation: true,
      auto_notify_agents: false,
      completion_percentage: 100
    }
  },
  { 
    name: 'cancelled', 
    display_name: 'Cancelado', 
    color: 'danger', 
    sort_order: 50,
    minimum_role_level: agent_level,
    metadata: {
      allows_modifications: false,
      requires_documentation: true,
      auto_notify_agents: true,
      completion_percentage: 0
    }
  }
]

business_statuses_data.each do |attrs|
  BusinessStatus.find_or_create_by!(name: attrs[:name]) do |bs|
    bs.display_name = attrs[:display_name]
    bs.color = attrs[:color]
    bs.sort_order = attrs[:sort_order]
    bs.minimum_role_level = attrs[:minimum_role_level]
    bs.metadata = attrs[:metadata]
    bs.active = true
  end
end

puts " ✅ #{BusinessStatus.count} estados de negocio creados"

# OperationTypes con configuración dinámica
operation_types_data = [
  { 
    name: 'sale', 
    display_name: 'Venta', 
    color: 'success',
    sort_order: 10,
    metadata: {
      requires_down_payment: true,
      default_commission_percentage: SystemConfiguration.get('business.default_commission_rate', 3.0),
      max_duration_months: nil,
      requires_guarantor: false,
      allows_co_ownership: true,
      required_document_categories: ['legal', 'financial', 'identity']
    }
  },
  { 
    name: 'rent', 
    display_name: 'Alquiler', 
    color: 'primary',
    sort_order: 20,
    metadata: {
      requires_down_payment: true,
      default_commission_percentage: 1.0,
      max_duration_months: 24,
      requires_guarantor: true,
      allows_co_ownership: false,
      required_document_categories: ['identity', 'financial', 'references']
    }
  },
  { 
    name: 'short_rent', 
    display_name: 'Alquiler Temporario', 
    color: 'info',
    sort_order: 30,
    metadata: {
      requires_down_payment: false,
      default_commission_percentage: 0.5,
      max_duration_months: 6,
      requires_guarantor: false,
      allows_co_ownership: false,
      required_document_categories: ['identity']
    }
  }
]

operation_types_data.each do |attrs|
  OperationType.find_or_create_by!(name: attrs[:name]) do |ot|
    ot.display_name = attrs[:display_name]
    ot.color = attrs[:color]
    ot.sort_order = attrs[:sort_order]
    ot.metadata = attrs[:metadata]
    ot.active = true
  end
end

puts " ✅ #{OperationType.count} tipos de operación creados"

# PropertyTypes con configuración dinámica
property_types_data = [
  { 
    name: 'house', 
    display_name: 'Casa', 
    description: 'Casa unifamiliar',
    sort_order: 10,
    icon: 'bi-house',
    metadata: {
      default_built_area_min: 50.0,
      default_built_area_max: 1000.0,
      requires_parking: true,
      allows_pets_by_default: true,
      standard_amenities: ['garden', 'terrace', 'parking'],
      required_fields: ['bedrooms', 'bathrooms', 'lot_area_m2']
    }
  },
  { 
    name: 'apartment', 
    display_name: 'Departamento', 
    description: 'Departamento en edificio',
    sort_order: 20,
    icon: 'bi-building',
    metadata: {
      default_built_area_min: 30.0,
      default_built_area_max: 300.0,
      requires_parking: false,
      allows_pets_by_default: false,
      standard_amenities: ['elevator', 'balcony'],
      required_fields: ['bedrooms', 'bathrooms']
    }
  },
  { 
    name: 'commercial', 
    display_name: 'Local Comercial', 
    description: 'Propiedad para uso comercial',
    sort_order: 30,
    icon: 'bi-shop',
    metadata: {
      default_built_area_min: 20.0,
      default_built_area_max: 5000.0,
      requires_parking: true,
      allows_pets_by_default: false,
      standard_amenities: ['security', 'access_control'],
      required_fields: ['built_area_m2', 'parking_spaces']
    }
  }
]

property_types_data.each do |attrs|
  PropertyType.find_or_create_by!(name: attrs[:name]) do |pt|
    pt.display_name = attrs[:display_name]
    pt.description = attrs[:description]
    pt.sort_order = attrs[:sort_order]
    pt.icon = attrs[:icon]
    pt.metadata = attrs[:metadata]
    pt.active = true
  end
end

puts " ✅ #{PropertyType.count} tipos de propiedad creados"

puts "✅ Catálogos de negocio configurados exitosamente"