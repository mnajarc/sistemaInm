puts "🔧 Creando configuraciones del sistema..."

# Configuraciones de roles
role_configs = [
  {
    key: 'roles.superadmin_max_level',
    value: '0',
    value_type: 'integer',
    category: 'roles',
    description: 'Nivel máximo para roles de SuperAdmin'
  },
  {
    key: 'roles.admin_max_level', 
    value: '10',
    value_type: 'integer',
    category: 'roles',
    description: 'Nivel máximo para roles de Admin'
  },
  {
    key: 'roles.agent_max_level',
    value: '20', 
    value_type: 'integer',
    category: 'roles',
    description: 'Nivel máximo para roles de Agente'
  },
  {
    key: 'roles.default_level',
    value: '999',
    value_type: 'integer', 
    category: 'roles',
    description: 'Nivel por defecto para roles no configurados'
  },
  {
    key: 'roles.default_role_name',
    value: 'client',
    value_type: 'string',
    category: 'roles', 
    description: 'Nombre del rol por defecto para nuevos usuarios'
  },
  {
    key: 'roles.superadmin_names',
    value: '["superadmin"]',
    value_type: 'array',
    category: 'roles',
    description: 'Nombres de roles considerados SuperAdmin'
  },
  {
    key: 'roles.admin_names', 
    value: '["admin"]',
    value_type: 'array',
    category: 'roles',
    description: 'Nombres de roles considerados Admin'
  },
  {
    key: 'roles.agent_names',
    value: '["agent"]', 
    value_type: 'array',
    category: 'roles',
    description: 'Nombres de roles considerados Agente'
  },
  {
    key: 'roles.client_names',
    value: '["client"]',
    value_type: 'array', 
    category: 'roles',
    description: 'Nombres de roles considerados Cliente'
  }
]

# Configuraciones de negocio
business_configs = [
  {
    key: 'business.active_statuses',
    value: '["available", "reserved"]',
    value_type: 'array',
    category: 'business',
    description: 'Estados considerados activos para transacciones'
  },
  {
    key: 'business.completed_statuses', 
    value: '["sold", "rented"]',
    value_type: 'array',
    category: 'business',
    description: 'Estados considerados completados para transacciones'
  },
  {
    key: 'business.in_progress_statuses',
    value: '["reserved"]',
    value_type: 'array', 
    category: 'business',
    description: 'Estados considerados en progreso para transacciones'
  },
  {
    key: 'business.available_status_name',
    value: 'available',
    value_type: 'string',
    category: 'business',
    description: 'Nombre del estado "disponible"'
  },
  {
    key: 'business.total_ownership_percentage',
    value: '100.0',
    value_type: 'decimal',
    category: 'business', 
    description: 'Porcentaje total requerido para propiedad'
  }
]

# Configuraciones de propiedades
property_configs = [
  {
    key: 'property.max_price',
    value: '1000000000',
    value_type: 'integer',
    category: 'property',
    description: 'Precio máximo permitido para propiedades'
  },
  {
    key: 'property.max_title_length',
    value: '255',
    value_type: 'integer',
    category: 'property', 
    description: 'Longitud máxima para títulos de propiedades'
  },
  {
    key: 'property.max_description_length',
    value: '10000',
    value_type: 'integer',
    category: 'property',
    description: 'Longitud máxima para descripciones de propiedades'
  },
  {
    key: 'property.available_statuses',
    value: '["available", "reserved"]',
    value_type: 'array',
    category: 'property',
    description: 'Estados considerados disponibles para propiedades'
  },
  {
    key: 'property.sale_operation_names',
    value: '["sale"]',
    value_type: 'array', 
    category: 'property',
    description: 'Nombres de operaciones consideradas de venta'
  },
  {
    key: 'property.rent_operation_names',
    value: '["rent"]',
    value_type: 'array',
    category: 'property', 
    description: 'Nombres de operaciones consideradas de alquiler'
  },
  {
    key: 'property.allowed_html_tags',
    value: '["p", "br", "strong", "em"]',
    value_type: 'array',
    category: 'property',
    description: 'Etiquetas HTML permitidas en descripciones'
  }
]

# Crear todas las configuraciones
all_configs = role_configs + business_configs + property_configs

all_configs.each do |config_attrs|
  SystemConfiguration.find_or_create_by!(key: config_attrs[:key]) do |config|
    config.assign_attributes(config_attrs.except(:key))
    config.system_config = true
    config.active = true
  end
end

puts "✅ #{all_configs.length} configuraciones del sistema creadas"