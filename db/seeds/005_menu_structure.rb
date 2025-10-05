puts "📱 Creando estructura de menús dinámicos..."

# Configuración de menús desde SystemConfiguration
menu_configs = SystemConfiguration.get('menu.structure', {
  'main_menus' => [
    {
      'name' => 'properties',
      'display_name' => 'Propiedades',
      'path' => '/properties',
      'icon' => 'bi-house-door',
      'sort_order' => 10,
      'minimum_role_level' => agent_level
    },
    {
      'name' => 'transactions',
      'display_name' => 'Transacciones',
      'path' => '/business_transactions',
      'icon' => 'bi-briefcase',
      'sort_order' => 20,
      'minimum_role_level' => agent_level
    }
  ],
  'admin_menus' => [
    {
      'name' => 'administration',
      'display_name' => 'Administración',
      'path' => '#',
      'icon' => 'bi-gear',
      'sort_order' => 90,
      'minimum_role_level' => admin_level,
      'children' => [
        {
          'name' => 'users',
          'display_name' => 'Usuarios',
          'path' => '/admin/users',
          'icon' => 'bi-people',
          'sort_order' => 10
        },
        {
          'name' => 'property_types',
          'display_name' => 'Tipos de Propiedad',
          'path' => '/admin/property_types',
          'icon' => 'bi-house',
          'sort_order' => 20
        }
      ]
    }
  ],
  'superadmin_menus' => [
    {
      'name' => 'superadmin',
      'display_name' => 'SuperAdmin',
      'path' => '#',
      'icon' => 'bi-shield-lock',
      'sort_order' => 100,
      'minimum_role_level' => superadmin_level,
      'children' => [
        {
          'name' => 'roles',
          'display_name' => 'Roles',
          'path' => '/superadmin/roles',
          'icon' => 'bi-person-badge',
          'sort_order' => 10
        },
        {
          'name' => 'menu_items',
          'display_name' => 'Estructura de Menús',
          'path' => '/superadmin/menu_items',
          'icon' => 'bi-list',
          'sort_order' => 20
        },
        {
          'name' => 'system_configurations',
          'display_name' => 'Configuraciones',
          'path' => '/superadmin/system_configurations',
          'icon' => 'bi-sliders',
          'sort_order' => 30
        }
      ]
    }
  ]
})

# Función para crear menús recursivamente
def create_menu_items(menu_data, parent_id = nil)
  menu_data.each do |menu_attrs|
    menu_item = MenuItem.find_or_create_by!(name: menu_attrs['name']) do |item|
      item.display_name = menu_attrs['display_name']
      item.path = menu_attrs['path']
      item.icon = menu_attrs['icon']
      item.parent_id = parent_id
      item.sort_order = menu_attrs['sort_order']
      item.minimum_role_level = menu_attrs['minimum_role_level'] || 999
      item.active = true
      item.system_menu = true
    end
    
    # Crear submenús si existen
    if menu_attrs['children']
      create_menu_items(menu_attrs['children'], menu_item.id)
    end
    
    puts " ✅ Menú: #{menu_attrs['display_name']}"
  end
end

# Crear todas las estructuras de menú
menu_configs.each do |category, menus|
  puts "📂 Creando menús: #{category}"
  create_menu_items(menus)
end

puts "✅ #{MenuItem.count} elementos de menú creados"

# Asignar permisos de menú automáticamente
puts "🔐 Asignando permisos de menú..."

Role.active.each do |role|
  MenuItem.active.each do |menu_item|
    if role.level <= menu_item.minimum_role_level
      RoleMenuPermission.find_or_create_by!(role: role, menu_item: menu_item) do |perm|
        perm.can_view = true
        perm.can_edit = role.level <= admin_level
      end
    end
  end
end

puts "✅ #{RoleMenuPermission.count} permisos de menú asignados"

puts "\n🎉 Sistema completamente inicializado sin hardcoding!"
puts "📊 Resumen:"
puts " - Configuraciones: #{SystemConfiguration.count}"
puts " - Roles: #{Role.count}"
puts " - Estados de negocio: #{BusinessStatus.count}"
puts " - Tipos de operación: #{OperationType.count}"
puts " - Tipos de propiedad: #{PropertyType.count}"
puts " - Usuarios: #{User.count}"
puts " - Elementos de menú: #{MenuItem.count}"
puts " - Permisos: #{RoleMenuPermission.count}"