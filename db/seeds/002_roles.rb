puts "📋 Creando roles del sistema..."

# Obtener configuraciones de roles
superadmin_level = SystemConfiguration.get('roles.superadmin_max_level', 0)
admin_level = SystemConfiguration.get('roles.admin_max_level', 10)
agent_level = SystemConfiguration.get('roles.agent_max_level', 20)
client_level = SystemConfiguration.get('roles.client_max_level', 30)

roles_data = [
  {
    name: 'superadmin',
    display_name: 'SuperAdministrador', 
    level: superadmin_level,
    system_role: true,
    description: 'Acceso completo al sistema, configuración de roles y menús'
  },
  {
    name: 'admin',
    display_name: 'Administrador',
    level: admin_level,
    system_role: true,
    description: 'Gestión de usuarios, propiedades y documentos'
  },
  {
    name: 'agent', 
    display_name: 'Agente Inmobiliario',
    level: agent_level,
    system_role: true,
    description: 'Gestión de propiedades y transacciones'
  },
  {
    name: 'client',
    display_name: 'Cliente',
    level: client_level,
    system_role: true,
    description: 'Consulta de propiedades disponibles'
  }
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

puts "✅ #{Role.count} roles creados"