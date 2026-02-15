
# lib/tasks/audit_co_owner_consistency.rake
namespace :audit do
  desc "Detecta inconsistencias entre offering_client_id y copropietarios"
  task co_owner_consistency: :environment do
    puts "=" * 70
    puts "AUDITORÍA: Consistencia offering_client vs co_owners"
    puts "=" * 70

    inconsistencies = 0
    no_co_owners = 0
    orphaned_acquiring = 0

    BusinessTransaction.includes(
      :offering_client, :acquiring_client, :business_transaction_co_owners
    ).find_each do |bt|

      co_owners = bt.business_transaction_co_owners.where(active: true)

      # 1. BT sin copropietarios activos
      if co_owners.empty?
        no_co_owners += 1
        puts "⚠️  BT ##{bt.id}: Sin copropietarios activos"
        next
      end

      # 2. offering_client no está entre co_owners
      co_owner_client_ids = co_owners.pluck(:client_id).compact
      unless co_owner_client_ids.include?(bt.offering_client_id)
        inconsistencies += 1
        puts "🔴 BT ##{bt.id}: offering_client_id=#{bt.offering_client_id} " \
             "NO está en co_owners #{co_owner_client_ids}"
      end

      # 3. Porcentajes no suman 100
      total_pct = co_owners.sum(:percentage).round(2)
      unless total_pct == 100.0
        puts "🟡 BT ##{bt.id}: Porcentajes suman #{total_pct}% (esperado 100%)"
      end

      # 4. acquiring_client huérfano
      if bt.acquiring_client_id.present?
        # Verificar si hay co_owners tipo adquiriente (futuro)
        orphaned_acquiring += 1
      end
    end

    puts "=" * 70
    puts "RESUMEN:"
    puts "  Total BTs:                    #{BusinessTransaction.count}"
    puts "  Sin copropietarios activos:   #{no_co_owners}"
    puts "  Inconsistencias offering:     #{inconsistencies}"
    puts "  Con acquiring_client (legacy):#{orphaned_acquiring}"
    puts "=" * 70
  end
end
