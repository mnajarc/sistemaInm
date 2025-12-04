# db/seeds/99_sample_data.rb
puts "🌱 Creando datos de prueba..."

return if Rails.env.production?

# 1. Obtener usuario
user = User.first

unless user
  puts "❌ No hay usuarios en el sistema"
  puts "   Ejecuta: rails db:seed (para crear usuarios base)"
  exit
end

puts "✅ Usuario: #{user.email} (ID: #{user.id})"

# 2. Buscar o crear agente
agent = user.agent

unless agent
  agent = Agent.create!(
    user: user,
    license_number: "LIC-#{Time.now.to_i}",
    phone: '5512345678',
    specialties: 'Residencial, Comercial',
    commission_rate: 3.5,
    is_active: true
  )
  puts "✅ Agente creado: #{agent.license_number} (ID: #{agent.id})"
else
  puts "✅ Agente existente: #{agent.license_number} (ID: #{agent.id})"
end

# 3. Verificar que agent.id exista
puts "\n🔍 Verificación:"
puts "   Agent ID: #{agent.id}"
puts "   User ID: #{user.id}"
puts "   Agent.user_id: #{agent.user_id}"

# 4. Crear formularios
forms_data = [
  {
    owner: 'Juan Pérez García',
    phone: '5512345678',
    email: 'juan@example.com',
    street: 'Av. Insurgentes Sur',
    number: '1500',
    neighborhood: 'Del Valle',
    postal_code: '03100',
    municipality: 'Benito Juárez',
    city: 'Ciudad de México'
  },
  {
    owner: 'María López Fernández',
    phone: '5587654321',
    email: 'maria@example.com',
    street: 'Av. Insurgentes Sur',
    number: '1500',
    neighborhood: 'Del Valle',
    postal_code: '03100',
    municipality: 'Benito Juárez',
    city: 'Ciudad de México'
  },
  {
    owner: 'Juan Pérez García',
    phone: '5512345678',
    email: 'juan@example.com',
    street: 'Av. Reforma',
    number: '320',
    neighborhood: 'Cuauhtémoc',
    postal_code: '06600',
    municipality: 'Cuauhtémoc',
    city: 'Ciudad de México'
  }
]

puts "\n🏗️ Creando formularios con agent_id: #{agent.id}"

forms_data.each_with_index do |data, idx|
  begin
    form = InitialContactForm.create!(
      agent_id: agent.id,  # ✅ EXPLÍCITO
      status: :completed,
      operation_type_id: OperationType.first.id,
      property_acquisition_method_id: PropertyAcquisitionMethod.first.id,
      contract_signer_type_id: ContractSignerType.first.id,
      
      general_conditions: {
        'owner_or_representative_name' => data[:owner],
        'owner_phone' => data[:phone],
        'owner_email' => data[:email],
        'civil_status' => 'casado'
      },
      
      acquisition_details: {
        'state' => 'Ciudad de México',
        'land_use' => 'HAB',
        'co_owners_count' => 1
      },
      
      property_info: {
        'street' => data[:street],
        'exterior_number' => data[:number],
        'neighborhood' => data[:neighborhood],
        'postal_code' => data[:postal_code],
        'municipality' => data[:municipality],
        'city' => data[:city],
        'country' => 'México'
      },
      
      current_status: {}
    )
    
    puts "✅ Form #{idx + 1}: #{form.property_human_identifier} (agent_id: #{form.agent_id})"
  rescue => e
    puts "❌ Error Form #{idx + 1}: #{e.message}"
    puts "   Backtrace: #{e.backtrace.first(2).join("\n   ")}"
  end
end

puts "\n📊 Resumen: #{InitialContactForm.count} formularios creados"
puts "🎉 Seeds completados!"