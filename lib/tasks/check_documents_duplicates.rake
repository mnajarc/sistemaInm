# lib/tasks/check_document_duplicates.rake
namespace :inspira do
  desc "Detectar duplicados en document_submissions (solo lectura)"
  task check_document_duplicates: :environment do
    puts "=" * 80
    puts "🔍 DETECTANDO DUPLICADOS EN DOCUMENT_SUBMISSIONS"
    puts "=" * 80
    
    # Caso 1: Duplicados CON copropietario
    duplicates_with_co_owner = DocumentSubmission
      .where.not(business_transaction_co_owner_id: nil)
      .group(:business_transaction_id, :document_type_id, :business_transaction_co_owner_id)
      .having('COUNT(*) > 1')
      .count
    
    puts "\n📊 DUPLICADOS CON COPROPIETARIO: #{duplicates_with_co_owner.count}"
    if duplicates_with_co_owner.any?
      duplicates_with_co_owner.each do |(bt_id, dt_id, co_owner_id), count|
        bt = BusinessTransaction.find(bt_id)
        dt = DocumentType.find(dt_id)
        co_owner = BusinessTransactionCoOwner.find(co_owner_id)
        
        puts "\n  ⚠️  BT #{bt_id} | #{dt.name} | #{co_owner.person_name}"
        puts "     Duplicados: #{count}"
        
        # Mostrar IDs específicos
        doc_ids = DocumentSubmission
          .where(
            business_transaction_id: bt_id,
            document_type_id: dt_id,
            business_transaction_co_owner_id: co_owner_id
          )
          .pluck(:id)
        puts "     IDs: #{doc_ids.join(', ')}"
      end
    else
      puts "  ✅ No se encontraron duplicados"
    end
    
    # Caso 2: Duplicados SIN copropietario
    duplicates_without_co_owner = DocumentSubmission
      .where(business_transaction_co_owner_id: nil)
      .group(:business_transaction_id, :document_type_id, :party_type)
      .having('COUNT(*) > 1')
      .count
    
    puts "\n📊 DUPLICADOS SIN COPROPIETARIO: #{duplicates_without_co_owner.count}"
    if duplicates_without_co_owner.any?
      duplicates_without_co_owner.each do |(bt_id, dt_id, party_type), count|
        bt = BusinessTransaction.find(bt_id)
        dt = DocumentType.find(dt_id)
        
        puts "\n  ⚠️  BT #{bt_id} | #{dt.name} | #{party_type}"
        puts "     Duplicados: #{count}"
        
        doc_ids = DocumentSubmission
          .where(
            business_transaction_id: bt_id,
            document_type_id: dt_id,
            party_type: party_type,
            business_transaction_co_owner_id: nil
          )
          .pluck(:id)
        puts "     IDs: #{doc_ids.join(', ')}"
      end
    else
      puts "  ✅ No se encontraron duplicados"
    end
    
    puts "\n" + "=" * 80
    puts "✅ DETECCIÓN COMPLETADA"
    puts "=" * 80
    
    if duplicates_with_co_owner.any? || duplicates_without_co_owner.any?
      puts "\n⚠️  ACCIÓN REQUERIDA:"
      puts "   1. Revisar manualmente duplicados listados arriba"
      puts "   2. Decidir cuáles conservar (último creado?)"
      puts "   3. Crear script de limpieza específico"
      puts "   4. NO ejecutar migración de índices hasta limpiar"
    else
      puts "\n✅ Sistema limpio. Seguro ejecutar migración de índices."
    end
  end
end
