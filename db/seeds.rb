# db/seeds.rb

puts "🌱 Iniciando seeds del sistema..."
# db/seeds.rb
=begin
roles_data = [
  { name: 'superadmin', display_name: 'SuperAdministrador', level: 0, system_role: true },
  { name: 'admin',      display_name: 'Administrador',       level: 10, system_role: true },
  { name: 'agent',      display_name: 'Agente Inmobiliario', level: 20, system_role: true },
  { name: 'client',     display_name: 'Cliente',             level: 30, system_role: true }
]

roles_data.each do |attrs|
  Role.find_or_create_by!(name: attrs[:name]) do |r|
    r.display_name = attrs[:display_name]
    r.level        = attrs[:level]
    r.system_role  = attrs[:system_role]
    r.active       = true
    r.description  = attrs[:description]
  end
end

# ==============================================================================
# ROLES DEL SISTEMA
# ==============================================================================
puts "📋 Creando roles del sistema..."

superadmin_role = Role.find_or_create_by!(name: 'superadmin') do |role|
  role.display_name = 'SuperAdministrador'
  role.description = 'Acceso completo al sistema, configuración de roles y menús'
  role.level = 0
  role.system_role = true
  puts "  ✅ Creado rol: SuperAdministrador (nivel 0)"
end

admin_role = Role.find_or_create_by!(name: 'admin') do |role|
  role.display_name = 'Administrador'
  role.description = 'Gestión de usuarios, propiedades y documentos'
  role.level = 10
  role.system_role = true
  puts "  ✅ Creado rol: Administrador (nivel 10)"
end

agent_role = Role.find_or_create_by!(name: 'agent') do |role|
  role.display_name = 'Agente Inmobiliario'
  role.description = 'Gestión de propiedades y documentos'
  role.level = 20
  role.system_role = true
  puts "  ✅ Creado rol: Agente (nivel 20)"
end

client_role = Role.find_or_create_by!(name: 'client') do |role|
  role.display_name = 'Cliente'
  role.description = 'Consulta de propiedades disponibles'
  role.level = 30
  role.system_role = true
  puts "  ✅ Creado rol: Cliente (nivel 30)"
end

# ==============================================================================
# ESTRUCTURA DE MENÚS
# ==============================================================================
puts "📱 Creando estructura de menús..."

# Menú raíz (invisible)
main_menu = MenuItem.find_or_create_by!(name: 'main') do |item|
  item.display_name = 'Menú Principal'
  item.path = nil
  item.icon = nil
  item.minimum_role_level = 30 # Todos pueden ver
  item.sort_order = 0
  item.system_menu = true
end
puts "  📁 Menú raíz creado"

# MENÚS DE PROPIEDADES
properties_menu = MenuItem.find_or_create_by!(name: 'properties') do |item|
  item.display_name = 'Propiedades'
  item.path = '/properties'
  item.icon = 'bi-house-door'
  item.parent_id = main_menu.id
  item.sort_order = 10
  item.minimum_role_level = 30 # Todos
  item.system_menu = true
end
puts "  🏠 Menú Propiedades creado"

new_property_menu = MenuItem.find_or_create_by!(name: 'new_property') do |item|
  item.display_name = 'Nueva Propiedad'
  item.path = '/properties/new'
  item.icon = 'bi-plus-circle'
  item.parent_id = main_menu.id
  item.sort_order = 20
  item.minimum_role_level = 20 # Solo agentes y arriba
  item.system_menu = true
end
puts "  ➕ Menú Nueva Propiedad creado"

# MENÚ DE ADMINISTRACIÓN
admin_menu = MenuItem.find_or_create_by!(name: 'administration') do |item|
  item.display_name = 'Administración'
  item.path = nil
  item.icon = 'bi-gear'
  item.parent_id = main_menu.id
  item.sort_order = 100
  item.minimum_role_level = 10 # Solo admins y superadmins
  item.system_menu = true
end
puts "  ⚙️ Menú Administración creado"

# Submenús de administración
doc_types_menu = MenuItem.find_or_create_by!(name: 'document_types') do |item|
  item.display_name = 'Tipos de Documento'
  item.path = '/admin/document_types'
  item.icon = 'bi-file-text'
  item.parent_id = admin_menu.id
  item.sort_order = 10
  item.minimum_role_level = 10
  item.system_menu = true
end
puts "  📄 Submenu Tipos de Documento creado"

users_menu = MenuItem.find_or_create_by!(name: 'user_management') do |item|
  item.display_name = 'Gestión de Usuarios'
  item.path = '/admin/users'
  item.icon = 'bi-people'
  item.parent_id = admin_menu.id
  item.sort_order = 20
  item.minimum_role_level = 10
  item.system_menu = true
end
puts "  👥 Submenu Gestión de Usuarios creado"

# MENÚ DE SUPERADMINISTRACIÓN
superadmin_menu = MenuItem.find_or_create_by!(name: 'superadmin') do |item|
  item.display_name = 'SuperAdministración'
  item.path = nil
  item.icon = 'bi-shield-lock'
  item.parent_id = main_menu.id
  item.sort_order = 200
  item.minimum_role_level = 0 # Solo superadmin
  item.system_menu = true
end
puts "  🛡️ Menú SuperAdministración creado"

menu_config_menu = MenuItem.find_or_create_by!(name: 'menu_configuration') do |item|
  item.display_name = 'Configuración de Menús'
  item.path = '/superadmin/menu_items'
  item.icon = 'bi-list-ul'
  item.parent_id = superadmin_menu.id
  item.sort_order = 10
  item.minimum_role_level = 0
  item.system_menu = true
end
puts "  📋 Submenu Configuración de Menús creado"

role_config_menu = MenuItem.find_or_create_by!(name: 'role_configuration') do |item|
  item.display_name = 'Configuración de Roles'
  item.path = '/superadmin/roles'
  item.icon = 'bi-person-badge'
  item.parent_id = superadmin_menu.id
  item.sort_order = 20
  item.minimum_role_level = 0
  item.system_menu = true
end
puts "  🏷️ Submenu Configuración de Roles creado"

# ==============================================================================
# PERMISOS DE MENÚ
# ==============================================================================
puts "🔐 Asignando permisos de menú..."

[superadmin_role, admin_role, agent_role, client_role].each do |role|
  MenuItem.active.find_each do |menu_item|
    if role.level <= menu_item.minimum_role_level
      permission = RoleMenuPermission.find_or_create_by!(
        role: role,
        menu_item: menu_item
      ) do |perm|
        perm.can_view = true
        perm.can_edit = (role.level <= 10) # Solo admin y superadmin pueden editar
      end
      puts "    ✅ #{role.display_name} puede acceder a #{menu_item.display_name}" if permission.persisted?
    end
  end
end

# ==============================================================================
# USUARIO SUPERADMIN INICIAL
# ==============================================================================
puts "👤 Creando usuario SuperAdmin inicial..."
User.create!(
  email: 'superadmin@sistema.local', 
  password: 'SuperAdmin123!',
  role: Role.find_by(name: 'superadmin')  # ✅ Usar asociación
)

User.create!(
  email: 'admin@sistema.com',
  password: 'Admin123!', 
  role: Role.find_by(name: 'admin')
)
# IMPORTANTE: Cambiar estos datos antes de producción
superadmin_email = 'superadmin@sistema.local'
superadmin_password = 'SuperAdmin123!'

superadmin_user = User.find_or_create_by!(email: superadmin_email) do |user|
  user.password = superadmin_password
  user.password_confirmation = superadmin_password
  user.role = :superadmin
  puts "  ✅ Usuario SuperAdmin creado: #{superadmin_email}"
  puts "  🔑 Password temporal: #{superadmin_password}"
  puts "  ⚠️ CAMBIAR ESTAS CREDENCIALES EN PRODUCCIÓN"
end

if superadmin_user.persisted? && !superadmin_user.previously_new_record?
  puts "  ℹ️ Usuario SuperAdmin ya existía: #{superadmin_email}"
end

# ==============================================================================
# VERIFICACIÓN FINAL
# ==============================================================================
puts "\n🔍 Verificando instalación..."
puts "  Roles creados: #{Role.count}"
puts "  Menús creados: #{MenuItem.count}"
puts "  Permisos asignados: #{RoleMenuPermission.count}"
puts "  Usuarios SuperAdmin: #{User.superadmin.count}"

puts "\n✅ Seeds completados exitosamente!"
puts "\n📋 RESUMEN:"
puts "  SuperAdmin: #{superadmin_email} / #{superadmin_password}"
puts "  Acceso: http://localhost:3000"
puts "  Panel SuperAdmin estará disponible en: /superadmin"
puts "\n⚠️ IMPORTANTE: Cambiar credenciales del SuperAdmin en producción"

=end