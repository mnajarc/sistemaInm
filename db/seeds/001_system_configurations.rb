puts "🔧 Creando configuraciones base del sistema..."

# Helper para crear configuraciones
def create_config(key, value, value_type, category, description, metadata = {})
  SystemConfiguration.find_or_create_by!(key: key) do |config|
    config.value = value.to_s
    config.value_type = value_type
    config.category = category
    config.description = description
    config.metadata = metadata
    config.system_config = true
    config.active = true
  end
end

# Configuraciones de aplicación
app_configs = [
  ['app.name', 'Sistema Inmobiliario', 'string', 'application', 'Nombre de la aplicación'],
  ['app.version', '1.0.0', 'string', 'application', 'Versión actual de la aplicación'],
  ['app.environment', Rails.env, 'string', 'application', 'Ambiente de ejecución'],
  ['app.time_zone', 'America/Mexico_City', 'string', 'application', 'Zona horaria por defecto'],
  ['app.locale', 'es', 'string', 'application', 'Idioma por defecto'],
  ['app.currency', 'MXN', 'string', 'application', 'Moneda por defecto']
]

app_configs.each { |config| create_config(*config) }

# Configuraciones de autenticación
auth_configs = [
  ['auth.session_timeout_minutes', '60', 'integer', 'authentication', 'Tiempo de sesión en minutos'],
  ['auth.max_login_attempts', '5', 'integer', 'authentication', 'Intentos máximos de login'],
  ['auth.password_min_length', '8', 'integer', 'authentication', 'Longitud mínima de contraseña'],
  ['auth.require_password_confirmation', 'true', 'boolean', 'authentication', 'Requerir confirmación de contraseña'],
  ['auth.permitted_signup_keys', '["role"]', 'array', 'authentication', 'Campos permitidos en registro'],
  ['auth.default_user_active', 'true', 'boolean', 'authentication', 'Usuarios activos por defecto']
]

auth_configs.each { |config| create_config(*config) }

# Configuraciones de roles (centralizadas)
role_configs = [
  ['roles.superadmin_max_level', '0', 'integer', 'roles', 'Nivel máximo para SuperAdmin'],
  ['roles.admin_max_level', '10', 'integer', 'roles', 'Nivel máximo para Admin'],
  ['roles.agent_max_level', '20', 'integer', 'roles', 'Nivel máximo para Agente'],
  ['roles.client_max_level', '30', 'integer', 'roles', 'Nivel máximo para Cliente'],
  ['roles.default_level', '999', 'integer', 'roles', 'Nivel por defecto'],
  ['roles.default_role_name', 'client', 'string', 'roles', 'Rol por defecto para nuevos usuarios'],
  ['roles.superadmin_names', '["superadmin"]', 'array', 'roles', 'Nombres de roles SuperAdmin'],
  ['roles.admin_names', '["admin"]', 'array', 'roles', 'Nombres de roles Admin'],
  ['roles.agent_names', '["agent"]', 'array', 'roles', 'Nombres de roles Agente'],
  ['roles.client_names', '["client"]', 'array', 'roles', 'Nombres de roles Cliente']
]

role_configs.each { |config| create_config(*config) }

# Configuraciones de rutas
route_configs = [
  ['routes.role_redirects', '{"client": "client_root_path", "agent": "root_path", "admin": "root_path", "superadmin": "superadmin_root_path"}', 'hash', 'routes', 'Redirecciones por rol después del login'],
  ['routes.sign_out_redirect', 'new_user_session_path', 'string', 'routes', 'Redirección después del logout'],
  ['routes.access_denied_redirect', 'root_path', 'string', 'routes', 'Redirección cuando se niega acceso']
]

route_configs.each { |config| create_config(*config) }

# Configuraciones de business
business_configs = [
  ['business.active_statuses', '["available", "reserved"]', 'array', 'business', 'Estados activos de transacciones'],
  ['business.completed_statuses', '["sold", "rented"]', 'array', 'business', 'Estados completados de transacciones'],
  ['business.in_progress_statuses', '["reserved"]', 'array', 'business', 'Estados en progreso de transacciones'],
  ['business.available_status_name', 'available', 'string', 'business', 'Nombre del estado disponible'],
  ['business.reserved_status_name', 'reserved', 'string', 'business', 'Nombre del estado reservado'],
  ['business.total_ownership_percentage', '100.0', 'decimal', 'business', 'Porcentaje total de propiedad requerido'],
  ['business.default_commission_rate', '3.0', 'decimal', 'business', 'Tasa de comisión por defecto']
]

business_configs.each { |config| create_config(*config) }

# Configuraciones de propiedades
property_configs = [
  ['property.max_price', '1000000000', 'integer', 'property', 'Precio máximo permitido'],
  ['property.max_title_length', '255', 'integer', 'property', 'Longitud máxima del título'],
  ['property.max_description_length', '10000', 'integer', 'property', 'Longitud máxima de descripción'],
  ['property.default_bedrooms', '1', 'integer', 'property', 'Número de habitaciones por defecto'],
  ['property.default_bathrooms', '1', 'integer', 'property', 'Número de baños por defecto'],
  ['property.default_parking_spaces', '0', 'integer', 'property', 'Espacios de estacionamiento por defecto'],
  ['property.default_furnished', 'false', 'boolean', 'property', 'Amueblado por defecto'],
  ['property.default_pets_allowed', 'true', 'boolean', 'property', 'Mascotas permitidas por defecto'],
  ['property.items_per_page', '20', 'integer', 'property', 'Items por página en listados'],
  ['property.default_sort', 'created_at_desc', 'string', 'property', 'Ordenamiento por defecto'],
  ['property.allowed_html_tags', '["p", "br", "strong", "em", "ul", "li"]', 'array', 'property', 'Etiquetas HTML permitidas'],
  ['property.available_statuses', '["available", "reserved"]', 'array', 'property', 'Estados disponibles'],
  ['property.sale_operation_names', '["sale"]', 'array', 'property', 'Nombres de operaciones de venta'],
  ['property.rent_operation_names', '["rent", "short_rent"]', 'array', 'property', 'Nombres de operaciones de alquiler']
]

property_configs.each { |config| create_config(*config) }

# Configuraciones de interfaz
ui_configs = [
  ['ui.items_per_page_options', '[10, 20, 50, 100]', 'array', 'interface', 'Opciones de items por página'],
  ['ui.show_pagination_info', 'true', 'boolean', 'interface', 'Mostrar información de paginación'],
  ['ui.show_per_page_selector', 'true', 'boolean', 'interface', 'Mostrar selector de items por página'],
  ['ui.default_theme', 'light', 'string', 'interface', 'Tema por defecto'],
  ['ui.enable_dark_mode', 'true', 'boolean', 'interface', 'Habilitar modo oscuro'],
  ['ui.sidebar_collapsed_default', 'false', 'boolean', 'interface', 'Sidebar colapsado por defecto']
]

ui_configs.each { |config| create_config(*config) }

# Configuraciones de mensajes
message_configs = [
  ['messages.property_success', '{"created": "Propiedad creada exitosamente.", "updated": "Propiedad actualizada exitosamente.", "deleted": "Propiedad eliminada exitosamente."}', 'hash', 'messages', 'Mensajes de éxito para propiedades'],
  ['messages.property_errors', '{"delete_failed": "No se pudo eliminar la propiedad.", "insufficient_permissions": "No tienes permisos para esta acción."}', 'hash', 'messages', 'Mensajes de error para propiedades'],
  ['messages.transaction_success', '{"created": "Transacción creada exitosamente.", "updated": "Transacción actualizada exitosamente.", "agent_transferred": "Agente transferido exitosamente."}', 'hash', 'messages', 'Mensajes de éxito para transacciones'],
  ['messages.user_success', '{"created": "Usuario creado exitosamente.", "updated": "Usuario actualizado exitosamente.", "role_changed": "Rol cambiado exitosamente."}', 'hash', 'messages', 'Mensajes de éxito para usuarios']
]

message_configs.each { |config| create_config(*config) }

puts "✅ #{SystemConfiguration.count} configuraciones del sistema creadas"