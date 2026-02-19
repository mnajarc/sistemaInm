# lib/tasks/fix_primary_coowners.rake
namespace :coowners do
  desc "Actualizar is_primary basado en lógica de negocio legacy"
  task fix_primary: :environment do
    puts "🔄 Actualizando is_primary para copropietarios..."
    
    fixed_count = 0
    
    BusinessTransaction.includes(:business_transaction_co_owners).find_each do |bt|
      co_owners = bt.business_transaction_co_owners.where(active: true)
      next if co_owners.empty?
      
      # Si ya hay uno marcado como principal, saltar
      if co_owners.any?(&:is_primary)
        puts "  ✓ BT #{bt.id} ya tiene principal definido"
        next
      end
      
      # Buscar candidatos usando lógica legacy
      candidates = co_owners.select(&:should_be_primary?)
      
      principal = if candidates.any?
                    # Preferir el primero creado si hay varios candidatos
                    candidates.min_by(&:id)
                  else
                    # Fallback: el primero creado
                    co_owners.order(:id).first
                  end
      
      if principal
        principal.update_column(:is_primary, true)
        puts "  ✓ BT #{bt.id}: #{principal.display_name} marcado como principal"
        fixed_count += 1
      end
    end
    
    puts "\n✅ Proceso completado: #{fixed_count} transacciones actualizadas"
  end
end
