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

# OfferStatus.create!(name: 'pending',        status_code: 0, display_name: 'En Espera')
# OfferStatus.create!(name: 'in_evaluation',  status_code: 1, display_name: 'En Evaluación')
# OfferStatus.create!(name: 'accepted',       status_code: 2, display_name: 'Aceptada')
# OfferStatus.create!(name: 'rejected',       status_code: 3, display_name: 'Rechazada')
# OfferStatus.create!(name: 'withdrawn',      status_code: 4, display_name: 'Retirada')

# CoOwnershipType.create!([
  # { name: 'individual', display_name: 'Propietario único', ownership_mode: 'único', sort_order: 1 },
  # { name: 'mancomunados', display_name: 'Bienes mancomunados', ownership_mode: 'dividido', sort_order: 2 },
  # { name: 'herencia', display_name: 'Herederos', ownership_mode: 'dividido', sort_order: 3 },
  # { name: 'usufructo', display_name: 'Usufructo', ownership_mode: 'único', sort_order: 4 },
  # { name: 'societaria', display_name: 'Sociedad/Fideicomiso', ownership_mode: 'dividido', sort_order: 5 }
# ])

# db/seeds/01_catalogs_base.rb
# Seeds para poblar catálogos básicos del sistema inmobiliario

load Rails.root.join('db', 'seeds', '07_co_ownership_types.rb')

puts "🌱 Poblando catálogos básicos del sistema..."

# Estados de la República Mexicana
puts "📍 Creando Estados de la República..."
states_data = [
  { name: 'Aguascalientes', code: 'AGS', full_name: 'Estado de Aguascalientes', sort_order: 1 },
  { name: 'Baja California', code: 'BC', full_name: 'Estado de Baja California', sort_order: 2 },
  { name: 'Baja California Sur', code: 'BCS', full_name: 'Estado de Baja California Sur', sort_order: 3 },
  { name: 'Campeche', code: 'CAM', full_name: 'Estado de Campeche', sort_order: 4 },
  { name: 'Chiapas', code: 'CHIS', full_name: 'Estado de Chiapas', sort_order: 5 },
  { name: 'Chihuahua', code: 'CHIH', full_name: 'Estado de Chihuahua', sort_order: 6 },
  { name: 'Ciudad de México', code: 'CDMX', full_name: 'Ciudad de México', sort_order: 7 },
  { name: 'Coahuila', code: 'COAH', full_name: 'Estado de Coahuila de Zaragoza', sort_order: 8 },
  { name: 'Colima', code: 'COL', full_name: 'Estado de Colima', sort_order: 9 },
  { name: 'Durango', code: 'DGO', full_name: 'Estado de Durango', sort_order: 10 },
  { name: 'Estado de México', code: 'MEX', full_name: 'Estado de México', sort_order: 11 },
  { name: 'Guanajuato', code: 'GTO', full_name: 'Estado de Guanajuato', sort_order: 12 },
  { name: 'Guerrero', code: 'GRO', full_name: 'Estado de Guerrero', sort_order: 13 },
  { name: 'Hidalgo', code: 'HGO', full_name: 'Estado de Hidalgo', sort_order: 14 },
  { name: 'Jalisco', code: 'JAL', full_name: 'Estado de Jalisco', sort_order: 15 },
  { name: 'Michoacán', code: 'MICH', full_name: 'Estado de Michoacán de Ocampo', sort_order: 16 },
  { name: 'Morelos', code: 'MOR', full_name: 'Estado de Morelos', sort_order: 17 },
  { name: 'Nayarit', code: 'NAY', full_name: 'Estado de Nayarit', sort_order: 18 },
  { name: 'Nuevo León', code: 'NL', full_name: 'Estado de Nuevo León', sort_order: 19 },
  { name: 'Oaxaca', code: 'OAX', full_name: 'Estado de Oaxaca', sort_order: 20 },
  { name: 'Puebla', code: 'PUE', full_name: 'Estado de Puebla', sort_order: 21 },
  { name: 'Querétaro', code: 'QRO', full_name: 'Estado de Querétaro', sort_order: 22 },
  { name: 'Quintana Roo', code: 'QROO', full_name: 'Estado de Quintana Roo', sort_order: 23 },
  { name: 'San Luis Potosí', code: 'SLP', full_name: 'Estado de San Luis Potosí', sort_order: 24 },
  { name: 'Sinaloa', code: 'SIN', full_name: 'Estado de Sinaloa', sort_order: 25 },
  { name: 'Sonora', code: 'SON', full_name: 'Estado de Sonora', sort_order: 26 },
  { name: 'Tabasco', code: 'TAB', full_name: 'Estado de Tabasco', sort_order: 27 },
  { name: 'Tamaulipas', code: 'TAMS', full_name: 'Estado de Tamaulipas', sort_order: 28 },
  { name: 'Tlaxcala', code: 'TLAX', full_name: 'Estado de Tlaxcala', sort_order: 29 },
  { name: 'Veracruz', code: 'VER', full_name: 'Estado de Veracruz de Ignacio de la Llave', sort_order: 30 },
  { name: 'Yucatán', code: 'YUC', full_name: 'Estado de Yucatán', sort_order: 31 },
  { name: 'Zacatecas', code: 'ZAC', full_name: 'Estado de Zacatecas', sort_order: 32 }
]

states_data.each do |state_data|
  MexicanState.find_or_create_by(code: state_data[:code]) do |state|
    state.name = state_data[:name]
    state.full_name = state_data[:full_name]
    state.sort_order = state_data[:sort_order]
    state.active = true
  end
end

# Estados Civiles
puts "💑 Creando Estados Civiles..."
civil_statuses_data = [
  { name: 'soltero', display_name: 'Soltero(a)', description: 'Persona sin vínculo matrimonial', sort_order: 1 },
  { name: 'casado', display_name: 'Casado(a)', description: 'Persona unida en matrimonio civil', sort_order: 2 },
  { name: 'divorciado', display_name: 'Divorciado(a)', description: 'Persona con matrimonio disuelto legalmente', sort_order: 3 },
  { name: 'viudo', display_name: 'Viudo(a)', description: 'Persona cuyo cónyuge ha fallecido', sort_order: 4 },
  { name: 'union_libre', display_name: 'Unión Libre', description: 'Convivencia sin matrimonio civil', sort_order: 5 },
  { name: 'separado', display_name: 'Separado(a)', description: 'Separación de hecho sin divorcio legal', sort_order: 6 }
]

civil_statuses_data.each do |status_data|
  CivilStatus.find_or_create_by(name: status_data[:name]) do |status|
    status.display_name = status_data[:display_name]
    status.description = status_data[:description]
    status.sort_order = status_data[:sort_order]
    status.active = true
  end
end

# Tipos de Identificación
puts "🆔 Creando Tipos de Identificación..."
identification_types_data = [
  { name: 'ine', display_name: 'INE', description: 'Credencial para votar del INE', 
    issuing_authority: 'Instituto Nacional Electoral', validity_years: 10, sort_order: 1 },
  { name: 'pasaporte', display_name: 'Pasaporte', description: 'Pasaporte mexicano', 
    issuing_authority: 'Secretaría de Relaciones Exteriores', validity_years: 10, sort_order: 2 },
  { name: 'cedula_profesional', display_name: 'Cédula Profesional', description: 'Cédula profesional', 
    issuing_authority: 'Secretaría de Educación Pública', validity_years: 999, sort_order: 3 },
  { name: 'cartilla_militar', display_name: 'Cartilla Militar', description: 'Cartilla del Servicio Militar Nacional', 
    issuing_authority: 'SEDENA', validity_years: 999, sort_order: 4 },
  { name: 'licencia_conducir', display_name: 'Licencia de Conducir', description: 'Licencia de conducir vigente', 
    issuing_authority: 'Gobierno Estatal', validity_years: 3, sort_order: 5 }
]

identification_types_data.each do |id_data|
  IdentificationType.find_or_create_by(name: id_data[:name]) do |id_type|
    id_type.display_name = id_data[:display_name]
    id_type.description = id_data[:description]
    id_type.issuing_authority = id_data[:issuing_authority]
    id_type.validity_years = id_data[:validity_years]
    id_type.sort_order = id_data[:sort_order]
    id_type.active = true
  end
end

# Actos Jurídicos de Adquisición
puts "⚖️ Creando Actos Jurídicos de Adquisición..."
legal_acts_data = [
  { name: 'compraventa', display_name: 'Compraventa', category: 'Oneroso', 
    description: 'Contrato por el cual se transfiere la propiedad mediante precio', sort_order: 1 },
  { name: 'herencia_testamentaria', display_name: 'Herencia Testamentaria', category: 'Gratuito', 
    description: 'Transmisión de bienes por sucesión con testamento', sort_order: 2 },
  { name: 'herencia_intestamentaria', display_name: 'Herencia Intestamentaria', category: 'Gratuito', 
    description: 'Transmisión de bienes por sucesión sin testamento', sort_order: 3 },
  { name: 'donacion', display_name: 'Donación', category: 'Gratuito', 
    description: 'Transmisión gratuita de bienes entre vivos', sort_order: 4 },
  { name: 'adjudicacion_judicial', display_name: 'Adjudicación Judicial', category: 'Judicial', 
    description: 'Asignación de bienes por sentencia judicial', sort_order: 5 },
  { name: 'adjudicacion_divorcio', display_name: 'Adjudicación por Divorcio', category: 'Judicial', 
    description: 'Asignación de bienes en convenio de divorcio', sort_order: 6 }
]

legal_acts_data.each do |act_data|
  LegalAct.find_or_create_by(name: act_data[:name]) do |act|
    act.display_name = act_data[:display_name]
    act.category = act_data[:category]
    act.description = act_data[:description]
    act.sort_order = act_data[:sort_order]
    act.requires_notary = true
    act.active = true
  end
end

# Instituciones Financieras
puts "🏦 Creando Instituciones Financieras..."
financial_institutions_data = [
  { name: 'Banamex', short_name: 'Banamex', institution_type: 'Banco', code: '002', sort_order: 1 },
  { name: 'Bancomer', short_name: 'BBVA', institution_type: 'Banco', code: '012', sort_order: 2 },
  { name: 'Santander México', short_name: 'Santander', institution_type: 'Banco', code: '014', sort_order: 3 },
  { name: 'Banorte', short_name: 'Banorte', institution_type: 'Banco', code: '072', sort_order: 4 },
  { name: 'HSBC México', short_name: 'HSBC', institution_type: 'Banco', code: '021', sort_order: 5 },
  { name: 'Banco Azteca', short_name: 'Azteca', institution_type: 'Banco', code: '127', sort_order: 6 },
  { name: 'Scotiabank', short_name: 'Scotia', institution_type: 'Banco', code: '044', sort_order: 7 },
  { name: 'Infonavit', short_name: 'Infonavit', institution_type: 'Organismo', code: 'INF', sort_order: 8 },
  { name: 'Fovissste', short_name: 'Fovissste', institution_type: 'Organismo', code: 'FOV', sort_order: 9 }
]

financial_institutions_data.each do |inst_data|
  FinancialInstitution.find_or_create_by(name: inst_data[:name]) do |inst|
    inst.short_name = inst_data[:short_name]
    inst.institution_type = inst_data[:institution_type]
    inst.code = inst_data[:code]
    inst.sort_order = inst_data[:sort_order]
    inst.active = true
  end
end

# Tipos de Persona
puts "👤 Creando Tipos de Persona..."
person_types_data = [
  { name: 'PF', display_name: 'Persona Física', 
    description: 'Individuo con capacidad jurídica', tax_regime: 'Persona Física', sort_order: 1 },
  { name: 'PM', display_name: 'Persona Moral', 
    description: 'Entidad jurídica constituida legalmente', tax_regime: 'Persona Moral', sort_order: 2 },
  { name: 'FIDE', display_name: 'Fideicomiso', 
    description: 'Relación jurídica fiduciaria', tax_regime: 'Fideicomiso', sort_order: 3 }
]

person_types_data.each do |person_data|
  PersonType.find_or_create_by(name: person_data[:name]) do |person_type|
    person_type.display_name = person_data[:display_name]
    person_type.description = person_data[:description]
    person_type.tax_regime = person_data[:tax_regime]
    person_type.sort_order = person_data[:sort_order]
    person_type.active = true
  end
end

# Tipos de Firmantes de Contrato
puts "✍️ Creando Tipos de Firmantes de Contrato..."
signer_types_data = [
  { name: 'titular_registral', display_name: 'Titular Registral', 
    description: 'Propietario inscrito en el registro público', requires_power_of_attorney: false, sort_order: 1 },
  { name: 'apoderado', display_name: 'Apoderado', 
    description: 'Persona con poder notarial para actos de dominio', requires_power_of_attorney: true, sort_order: 2 },
  { name: 'representante_legal', display_name: 'Representante Legal', 
    description: 'Representante de persona moral', requires_power_of_attorney: true, sort_order: 3 },
  { name: 'albacea', display_name: 'Albacea', 
    description: 'Ejecutor testamentario o intestamentario', requires_power_of_attorney: false, sort_order: 4 },
  { name: 'tutor', display_name: 'Tutor', 
    description: 'Representante legal de menor o incapacitado', requires_power_of_attorney: false, sort_order: 5 }
]

signer_types_data.each do |signer_data|
  ContractSignerType.find_or_create_by(name: signer_data[:name]) do |signer_type|
    signer_type.display_name = signer_data[:display_name]
    signer_type.description = signer_data[:description]
    signer_type.requires_power_of_attorney = signer_data[:requires_power_of_attorney]
    signer_type.sort_order = signer_data[:sort_order]
    signer_type.active = true
  end
end

puts "✅ Catálogos básicos creados exitosamente!"
puts "📊 Resumen:"
puts "   - #{MexicanState.count} Estados de la República"
puts "   - #{CivilStatus.count} Estados Civiles"
puts "   - #{IdentificationType.count} Tipos de Identificación"
puts "   - #{LegalAct.count} Actos Jurídicos de Adquisición"
puts "   - #{FinancialInstitution.count} Instituciones Financieras"
puts "   - #{PersonType.count} Tipos de Persona"
puts "   - #{ContractSignerType.count} Tipos de Firmantes de Contrato"

# Seeds documentales
# load Rails.root.join('db', 'seeds', 'document_statuses.rb')
# load Rails.root.join('db', 'seeds', 'transaction_scenarios.rb')
# Cargar asociaciones documento-escenario
# load Rails.root.join('db', 'seeds', 'scenario_documents.rb')
# db/seeds.rb

# Cargar en orden de dependencias
puts "\n🚀 Iniciando seeds del sistema..."

# 1. Catálogos base (ya existentes)
puts "\n📚 Cargando catálogos base..."
load Rails.root.join('db', 'seeds', 'document_statuses.rb')
load Rails.root.join('db', 'seeds', 'transaction_scenarios.rb')

# 2. Tipos de documentos (NUEVO - debe ir ANTES de scenario_documents)
puts "\n📄 Cargando tipos de documentos..."
load Rails.root.join('db', 'seeds', 'document_types_complete.rb')

# 3. Asociaciones documento-escenario (NUEVO - depende de document_types)
puts "\n🔗 Asociando documentos a escenarios..."
load Rails.root.join('db', 'seeds', 'scenario_documents.rb')

puts "\n✅ Seeds completados exitosamente"

# Catálogos para sistema de adquisiciones
load Rails.root.join('db', 'seeds', '01_property_acquisition_methods.rb')
load Rails.root.join('db', 'seeds', '02_marriage_regimes.rb')
load Rails.root.join('db', 'seeds', '03_land_use_types.rb')

puts "\n✅ Seeds completados exitosamente"


puts "🌍 Cargando catálogo de países..."
load Rails.root.join('db', 'seeds', 'countries.rb')




puts "🌱 Sembrando RelationshipTypes..."

RelationshipType.find_or_create_by!(name: 'esposos') do |rt|
  rt.display_name = 'Esposos'
  rt.description = 'Relación matrimonial'
  rt.category = 'copropietario'
  rt.sort_order = 10
end

RelationshipType.find_or_create_by!(name: 'hermanos') do |rt|
  rt.display_name = 'Hermanos'
  rt.description = 'Relación fraterna'
  rt.category = 'copropietario'
  rt.sort_order = 20
end

RelationshipType.find_or_create_by!(name: 'padres_hijos') do |rt|
  rt.display_name = 'Padres e hijos'
  rt.description = 'Relación filial'
  rt.category = 'copropietario'
  rt.sort_order = 30
end

RelationshipType.find_or_create_by!(name: 'socios') do |rt|
  rt.display_name = 'Socios'
  rt.description = 'Relación comercial'
  rt.category = 'copropietario'
  rt.sort_order = 40
end

RelationshipType.find_or_create_by!(name: 'sin_relacion') do |rt|
  rt.display_name = 'Sin relación familiar'
  rt.description = 'No existe relación familiar o comercial'
  rt.category = 'copropietario'
  rt.sort_order = 99
end

# Relaciones para herencias
RelationshipType.find_or_create_by!(name: 'padre') do |rt|
  rt.display_name = 'Padre'
  rt.description = 'Padre del heredero'
  rt.category = 'herencia'
  rt.sort_order = 10
end

RelationshipType.find_or_create_by!(name: 'madre') do |rt|
  rt.display_name = 'Madre'
  rt.description = 'Madre del heredero'
  rt.category = 'herencia'
  rt.sort_order = 20
end

RelationshipType.find_or_create_by!(name: 'ambos_padres') do |rt|
  rt.display_name = 'Ambos padres'
  rt.description = 'Padre y madre del heredero'
  rt.category = 'herencia'
  rt.sort_order = 5
end

RelationshipType.find_or_create_by!(name: 'abuelo_paterno') do |rt|
  rt.display_name = 'Abuelo paterno'
  rt.category = 'herencia'
  rt.sort_order = 30
end

RelationshipType.find_or_create_by!(name: 'abuelo_materno') do |rt|
  rt.display_name = 'Abuelo materno'
  rt.category = 'herencia'
  rt.sort_order = 40
end

RelationshipType.find_or_create_by!(name: 'tio_tia') do |rt|
  rt.display_name = 'Tío/Tía'
  rt.category = 'herencia'
  rt.sort_order = 50
end

RelationshipType.find_or_create_by!(name: 'otro_familiar') do |rt|
  rt.display_name = 'Otro familiar'
  rt.category = 'herencia'
  rt.sort_order = 90
end

puts "✅ #{RelationshipType.count} RelationshipTypes creados"

# ═══════════════════════════════════════════════════════════════

puts "🌱 Sembrando SuccessionTypes..."

SuccessionType.find_or_create_by!(name: 'testamentaria') do |st|
  st.display_name = 'Testamentaria'
  st.description = 'Sucesión con testamento válido'
  st.requires_judicial = false
  st.sort_order = 10
end

SuccessionType.find_or_create_by!(name: 'intestada') do |st|
  st.display_name = 'Intestada (sin testamento)'
  st.description = 'Sucesión sin testamento'
  st.requires_judicial = true
  st.sort_order = 20
end

SuccessionType.find_or_create_by!(name: 'mixta') do |st|
  st.display_name = 'Mixta'
  st.description = 'Sucesión parcialmente testamentaria'
  st.requires_judicial = true
  st.sort_order = 30
end

puts "✅ #{SuccessionType.count} SuccessionTypes creados"

puts "🎉 Seeds completados"

puts "🌱 Sembrando SuccessionAuthorities..."

SuccessionAuthority.find_or_create_by!(name: 'notaria') do |sa|
  sa.display_name = 'Notaría'
  sa.description = 'Sucesión tramitada ante notario público'
  sa.category = 'notarial'
  sa.sort_order = 10
end

SuccessionAuthority.find_or_create_by!(name: 'juzgado_familiar') do |sa|
  sa.display_name = 'Juzgado Familiar'
  sa.description = 'Sucesión tramitada en juzgado familiar'
  sa.category = 'judicial'
  sa.sort_order = 20
end

SuccessionAuthority.find_or_create_by!(name: 'juzgado_civil') do |sa|
  sa.display_name = 'Juzgado Civil'
  sa.description = 'Sucesión tramitada en juzgado civil'
  sa.category = 'judicial'
  sa.sort_order = 30
end

SuccessionAuthority.find_or_create_by!(name: 'tribunal_superior') do |sa|
  sa.display_name = 'Tribunal Superior de Justicia'
  sa.description = 'Sucesión tramitada en tribunal superior'
  sa.category = 'judicial'
  sa.sort_order = 40
end

puts "✅ #{SuccessionAuthority.count} SuccessionAuthorities creadas"

load Rails.root.join('db', 'seeds', '99_sample_data.rb')
puts "🎉 Todas las tablas de catálogos completadas"
