puts "👤 Creando usuarios iniciales del sistema..."

# Obtener configuraciones para usuarios
default_password_length = SystemConfiguration.get('auth.password_min_length', 8)
require_confirmation = SystemConfiguration.get('auth.require_password_confirmation', true)

# Usuario SuperAdmin
superadmin_email = ENV['SUPERADMIN_EMAIL'] || 'superadmin@sistema.local'
superadmin_password = ENV['SUPERADMIN_PASSWORD'] || SecureRandom.alphanumeric(12)

superadmin_user = User.find_or_create_by!(email: superadmin_email) do |user|
  user.password = superadmin_password
  user.password_confirmation = superadmin_password if require_confirmation
  user.role = Role.find_by(name: 'superadmin')
  user.active = true
end

puts " ✅ SuperAdmin: #{superadmin_email}"
puts " 🔑 Password: #{superadmin_password}" if Rails.env.development?

# Usuario Admin
admin_email = ENV['ADMIN_EMAIL'] || 'admin@sistema.com'
admin_password = ENV['ADMIN_PASSWORD'] || SecureRandom.alphanumeric(10)

admin_user = User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password if require_confirmation
  user.role = Role.find_by(name: 'admin')
  user.active = true
end

puts " ✅ Admin: #{admin_email}"
puts " 🔑 Password: #{admin_password}" if Rails.env.development?

# Usuarios Agente (opcionales)
if Rails.env.development?
  agent_count = ENV['DEMO_AGENTS_COUNT']&.to_i || 2
  
  agent_count.times do |i|
    agent_email = "agente#{i+1}@sistema.com"
    agent_password = "Agent#{SecureRandom.alphanumeric(6)}"
    
    User.find_or_create_by!(email: agent_email) do |user|
      user.password = agent_password
      user.password_confirmation = agent_password if require_confirmation
      user.role = Role.find_by(name: 'agent')
      user.active = true
    end
    
    puts " ✅ Agente: #{agent_email} / #{agent_password}"
  end
end

puts "✅ #{User.count} usuarios creados"