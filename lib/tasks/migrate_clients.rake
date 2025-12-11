
namespace :clients do
  desc "Migrar datos de InitialContactForm a Client"
  task migrate_from_forms: :environment do
    puts "🔄 Iniciando migración de clientes desde InitialContactForm..."
    
    count = 0
    InitialContactForm.where(client_id: nil).find_each do |form|
      email = form.general_conditions&.dig('owner_email')
      
      if email.present?
        begin
          client = Client.from_initial_contact_form(form)
          
          if client.save
            form.update(client_id: client.id)
            puts "✅ Migrado: #{client.display_name} (#{email})"
            count += 1
          else
            puts "❌ Error guardando cliente #{email}: #{client.errors.full_messages.join(', ')}"
          end
        rescue StandardError => e
          puts "❌ Error procesando formulario #{form.id}: #{e.message}"
        end
      else
        puts "⚠️  Formulario #{form.id} sin email"
      end
    end
    
    puts "✅ Migración completada: #{count} clientes migrados"
  end
end
