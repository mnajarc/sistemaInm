# db/seeds.rb

puts "🌱 Iniciando seeds del sistema..."

# ===============================================================================
# ROLES DEL SISTEMA
# ===============================================================================
puts "📋 Creando roles del sistema..."

roles_data = [
  { name: 'superadmin', display_name: 'SuperAdministrador', level: 0, system_role: true,
    description: 'Acceso completo al sistema, configuración de roles y menús' },
  { name: 'admin', display_name: 'Administrador', level: 10, system_role: true,
    description: 'Gestión de usuarios, propiedades y documentos' },
  { name: 'agent', display_name: 'Agente Inmobiliario', level: 20, system_role: true,
    description: 'Gestión de propiedades y documentos' },
  { name: 'client', display_name: 'Cliente', level: 30, system_role: true,
    description: 'Consulta de propiedades disponibles' }
]

roles_data.each do |attrs|
  Role.find_or_create_by!(name: attrs[:name]) do |r|
    r.display_name = attrs[:display_name]
    r.level = attrs[:level]
    r.system_role = attrs[:system_role]
    r.description = attrs[:description]
    r.active = true
  end
  puts " ✅ Rol: #{attrs[:display_name]} (nivel #{attrs[:level]})"
end

# ===============================================================================
# ESTRUCTURA DE MENÚS COMPLETA
# ===============================================================================
puts "📱 Creando estructura completa de menús..."

# Buscar menú admin existente
admin_menu = MenuItem.find_by(name: 'administration')

if admin_menu
  # Actualizar menú admin para que sea dropdown
  admin_menu.update!(path: '#')
  
  # Submenús Admin actualizados
  admin_submenus = [
    { name: 'property_types', display_name: 'Tipos de Propiedad', path: '/admin/property_types', icon: 'bi-house', sort_order: 10 },
    { name: 'operation_types', display_name: 'Tipos de Operación', path: '/admin/operation_types', icon: 'bi-briefcase', sort_order: 20 },
    { name: 'business_statuses', display_name: 'Estados de Negocio', path: '/admin/business_statuses', icon: 'bi-flag', sort_order: 30 },
    { name: 'users', display_name: 'Gestión de Usuarios', path: '/admin/users', icon: 'bi-person-gear', sort_order: 40 },
  ]

  admin_submenus.each do |submenu_attrs|
    MenuItem.find_or_create_by!(name: submenu_attrs[:name]) do |item|
      item.display_name = submenu_attrs[:display_name]
      item.path = submenu_attrs[:path]
      item.icon = submenu_attrs[:icon]
      item.parent_id = admin_menu.id
      item.sort_order = submenu_attrs[:sort_order]
      item.minimum_role_level = 10
      item.active = true
      item.system_menu = true
    end
  end
  
  puts " ✅ Submenús administrativos actualizados"
end

# Crear menús principales si no existen
main_menus = [
  { name: 'properties', display_name: 'Propiedades', path: '/properties', icon: 'bi-house-door', sort_order: 10, level: 20 },
  { name: 'transactions', display_name: 'Transacciones', path: '/business_transactions', icon: 'bi-briefcase', sort_order: 20, level: 20 },
]

main_menus.each do |menu_attrs|
  MenuItem.find_or_create_by!(name: menu_attrs[:name]) do |item|
    item.display_name = menu_attrs[:display_name]
    item.path = menu_attrs[:path]
    item.icon = menu_attrs[:icon]
    item.parent_id = nil
    item.sort_order = menu_attrs[:sort_order]
    item.minimum_role_level = menu_attrs[:level]
    item.active = true
    item.system_menu = true
  end
end

# Buscar menú superadmin existente
superadmin_menu = MenuItem.find_by(name: 'superadmin')

if superadmin_menu
  # Actualizar para que sea dropdown si no lo es
  superadmin_menu.update!(path: '#') unless superadmin_menu.path == '#'
  
  puts " ✅ Menú SuperAdmin actualizado"
end

puts " ✅ Estructura de menús completa creada"

# ===============================================================================
# ASIGNACIÓN DE PERMISOS DE MENÚ ACTUALIZADA
# ===============================================================================
puts "🔐 Actualizando permisos de menú..."

# Asegurar que todos los menús tengan permisos correctos
Role.all.each do |role|
  MenuItem.where(active: true).each do |menu_item|
    # Solo crear permisos si el rol puede acceder al menú
    if role.level <= menu_item.minimum_role_level
      RoleMenuPermission.find_or_create_by!(role: role, menu_item: menu_item) do |perm|
        perm.can_view = true
        perm.can_edit = (role.level <= 10) # Solo admin y superadmin pueden editar
      end
    end
  end
end

puts " ✅ Permisos de menú actualizados correctamente"

# ===============================================================================
# CATÁLOGOS
# ===============================================================================

# Tipos de Propiedad
puts "🏠 Creando tipos de propiedad..."
property_types_data = [
  { name: 'house', display_name: 'Casa', description: 'Casa unifamiliar', sort_order: 1 },
  { name: 'apartment', display_name: 'Departamento', description: 'Departamento en edificio', sort_order: 2 },
  { name: 'commercial', display_name: 'Local Comercial', description: 'Propiedad para uso comercial', sort_order: 3 },
  { name: 'office', display_name: 'Oficina', description: 'Espacio de oficina', sort_order: 4 },
  { name: 'warehouse', display_name: 'Bodega', description: 'Espacio de almacenamiento', sort_order: 5 },
  { name: 'land', display_name: 'Terreno', description: 'Terreno para construcción', sort_order: 6 }
]

property_types_data.each do |attrs|
  PropertyType.find_or_create_by!(name: attrs[:name]) do |pt|
    pt.display_name = attrs[:display_name]
    pt.description = attrs[:description]
    pt.sort_order = attrs[:sort_order]
    pt.active = true
  end
end
puts " ✅ #{property_types_data.length} tipos de propiedad creados"

# Tipos de Operación
puts "💼 Creando tipos de operación..."
operation_types_data = [
  { name: 'sale', display_name: 'Venta', description: 'Venta de propiedad', sort_order: 1 },
  { name: 'rent', display_name: 'Alquiler', description: 'Alquiler a largo plazo', sort_order: 2 },
  { name: 'short_rent', display_name: 'Alquiler Temporario', description: 'Alquiler por días/semanas', sort_order: 3 }
]

operation_types_data.each do |attrs|
  OperationType.find_or_create_by!(name: attrs[:name]) do |ot|
    ot.display_name = attrs[:display_name]
    ot.description = attrs[:description]
    ot.sort_order = attrs[:sort_order]
    ot.active = true
  end
end
puts " ✅ #{operation_types_data.length} tipos de operación creados"

# Estados de Negocio
puts "📊 Creando estados de negocio..."
business_statuses_data = [
  { name: 'available', display_name: 'Disponible', color: 'success', sort_order: 1 },
  { name: 'reserved', display_name: 'Reservado', color: 'warning', sort_order: 2 },
  { name: 'sold', display_name: 'Vendido', color: 'info', sort_order: 3 },
  { name: 'rented', display_name: 'Alquilado', color: 'primary', sort_order: 4 },
  { name: 'cancelled', display_name: 'Cancelado', color: 'danger', sort_order: 5 }
]

business_statuses_data.each do |attrs|
  BusinessStatus.find_or_create_by!(name: attrs[:name]) do |bs|
    bs.display_name = attrs[:display_name]
    bs.color = attrs[:color]
    bs.sort_order = attrs[:sort_order]
    bs.active = true
  end
end
puts " ✅ #{business_statuses_data.length} estados de negocio creados"

# ===============================================================================
# CLIENTES DE EJEMPLO
# ===============================================================================
puts "👥 Creando clientes de ejemplo..."

client1 = Client.find_or_create_by!(email: 'juan.perez@email.com') do |c|
  c.name = 'Juan Pérez'
  c.phone = '+52 555 123 4567'
  c.address = 'Calle Principal 123, Ciudad'
end

client2 = Client.find_or_create_by!(email: 'maria.garcia@email.com') do |c|
  c.name = 'María García'
  c.phone = '+52 555 987 6543'
  c.address = 'Avenida Central 456, Ciudad'
end

puts " ✅ 2 clientes de ejemplo creados"

# ===============================================================================
# USUARIOS INICIALES
# ===============================================================================
puts "👤 Creando usuarios iniciales..."

superadmin_user = User.find_or_create_by!(email: 'superadmin@sistema.local') do |user|
  user.password = 'SuperAdmin123!'
  user.password_confirmation = 'SuperAdmin123!'
  user.role = Role.find_by(name: 'superadmin')
end

admin_user = User.find_or_create_by!(email: 'admin@sistema.com') do |user|
  user.password = 'Admin123!'
  user.password_confirmation = 'Admin123!'
  user.role = Role.find_by(name: 'admin')
end

puts " ✅ Usuarios iniciales creados"
puts " 🔑 SuperAdmin: superadmin@sistema.local / SuperAdmin123!"
puts " 🔑 Admin: admin@sistema.com / Admin123!"

# ===============================================================================
# VERIFICACIÓN FINAL
# ===============================================================================
puts "\n🔍 Verificación final..."
puts " Roles: #{Role.count}"
puts " Menús: #{MenuItem.count}"
puts " Permisos: #{RoleMenuPermission.count}"
puts " PropertyTypes: #{PropertyType.count}"
puts " OperationTypes: #{OperationType.count}"
puts " BusinessStatuses: #{BusinessStatus.count}"
puts " Clientes: #{Client.count}"
puts " Usuarios: #{User.count}"

puts "\n✅ Seeds completados exitosamente!"
puts "🚀 Sistema listo para usar"

# ===============================================================================
# AGENTES DE EJEMPLO
# ===============================================================================
puts "👨‍💼 Creando agentes de ejemplo..."

agent1 = User.find_or_create_by!(email: 'agente1@sistema.com') do |user|
  user.password = 'Agent123!'
  user.password_confirmation = 'Agent123!'
  user.role = Role.find_by(name: 'agent')
end

agent2 = User.find_or_create_by!(email: 'agente2@sistema.com') do |user|
  user.password = 'Agent123!'
  user.password_confirmation = 'Agent123!'
  user.role = Role.find_by(name: 'agent')
end

agent3 = User.find_or_create_by!(email: 'agente3@sistema.com') do |user|
  user.password = 'Agent123!'
  user.password_confirmation = 'Agent123!'
  user.role = Role.find_by(name: 'agent')
end

puts " ✅ 3 agentes creados"
puts " 🔑 Agente 1: agente1@sistema.com / Agent123!"
puts " 🔑 Agente 2: agente2@sistema.com / Agent123!"
puts " 🔑 Agente 3: agente3@sistema.com / Agent123!"

# ===============================================================================
# CLIENTE DE EJEMPLO CON PERFIL DE USUARIO
# ===============================================================================
puts "👤 Creando usuario cliente de ejemplo..."

client_user = User.find_or_create_by!(email: 'cliente1@email.com') do |user|
  user.password = 'Cliente123!'
  user.password_confirmation = 'Cliente123!'
  user.role = Role.find_by(name: 'client')
end

# Verificar si Client puede tener user_id
if Client.column_names.include?('user_id')
  # Si Client tiene relación con User
  if Client.exists?(email: 'cliente1@email.com')
    existing_client = Client.find_by(email: 'cliente1@email.com')
    existing_client.update(user: client_user)
  else
    Client.create!(
      name: 'Laura González',
      email: 'cliente1@email.com',
      phone: '+52 555 111 2222',
      address: 'Residencial Norte 789, Ciudad',
      user: client_user
    )
  end
else
  # Si Client NO tiene relación con User, solo actualizar cliente existente
  existing_client = Client.find_by(email: 'cliente1@email.com')
  if existing_client
    existing_client.update(name: 'Laura González (Usuario)')
  end
end

puts " ✅ Usuario cliente creado"
puts " 🔑 Cliente: cliente1@email.com / Cliente123!"
# db/seeds.rb (agregar al final)

# BusinessStatuses
business_statuses = [
  { name: 'available', display_name: 'Disponible', color: 'success', active: true, sort_order: 10 },
  { name: 'reserved', display_name: 'Reservado', color: 'warning', active: true, sort_order: 20 },
  { name: 'sold', display_name: 'Vendido', color: 'info', active: true, sort_order: 30 },
  { name: 'rented', display_name: 'Alquilado', color: 'primary', active: true, sort_order: 40 },
  { name: 'cancelled', display_name: 'Cancelado', color: 'danger', active: true, sort_order: 50 }
]

business_statuses.each do |attrs|
  BusinessStatus.find_or_create_by(name: attrs[:name]) do |bs|
    bs.assign_attributes(attrs)
  end
end

# OperationTypes  
operation_types = [
  { name: 'sale', display_name: 'Venta', active: true, sort_order: 10 },
  { name: 'rent', display_name: 'Alquiler', active: true, sort_order: 20 },
  { name: 'short_rent', display_name: 'Alquiler Temporario', active: true, sort_order: 30 }
]

operation_types.each do |attrs|
  OperationType.find_or_create_by(name: attrs[:name]) do |ot|
    ot.assign_attributes(attrs)
  end
end

puts "✅ BusinessStatuses y OperationTypes creados"
# Roles de Copropiedad configurables
co_ownership_roles = [
  { name: 'vendedor', display_name: 'Vendedor', description: 'Persona que vende la propiedad', sort_order: 10 },
  { name: 'heredero_vendedor', display_name: 'Heredero (Vendedor)', description: 'Heredero que vende propiedad heredada', sort_order: 15 },
  { name: 'comprador', display_name: 'Comprador', description: 'Persona que adquiere la propiedad', sort_order: 20 },
  { name: 'legatario', display_name: 'Legatario', description: 'Beneficiario de legado específico', sort_order: 30 },
  { name: 'representante', display_name: 'Representante Legal', description: 'Actúa en nombre de otro', sort_order: 40 },
  { name: 'fideicomisario', display_name: 'Fideicomisario', description: 'Beneficiario de fideicomiso', sort_order: 50 },
  { name: 'otro', display_name: 'Otro', description: 'Otra participación no especificada', sort_order: 99 }
]


co_ownership_roles.each do |attrs|
  CoOwnershipRole.find_or_create_by(name: attrs[:name]) do |role|
    role.assign_attributes(attrs)
  end
end

puts "✅ #{CoOwnershipRole.count} roles de copropiedad configurados"

require_relative 'seeds/roles'
require_relative 'seeds/operation_types'
require_relative 'seeds/business_statuses'
require_relative 'seeds/menu_items'

OfferStatus.create!(name: 'pending',        status_code: 0, display_name: 'En Espera')
OfferStatus.create!(name: 'in_evaluation',  status_code: 1, display_name: 'En Evaluación')
OfferStatus.create!(name: 'accepted',       status_code: 2, display_name: 'Aceptada')
OfferStatus.create!(name: 'rejected',       status_code: 3, display_name: 'Rechazada')
OfferStatus.create!(name: 'withdrawn',      status_code: 4, display_name: 'Retirada')

CoOwnershipType.create!([
  { name: 'individual', display_name: 'Propietario único', ownership_mode: 'único', sort_order: 1 },
  { name: 'mancomunados', display_name: 'Bienes mancomunados', ownership_mode: 'dividido', sort_order: 2 },
  { name: 'herencia', display_name: 'Herederos', ownership_mode: 'dividido', sort_order: 3 },
  { name: 'usufructo', display_name: 'Usufructo', ownership_mode: 'único', sort_order: 4 },
  { name: 'societaria', display_name: 'Sociedad/Fideicomiso', ownership_mode: 'dividido', sort_order: 5 }
])


