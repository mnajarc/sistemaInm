namespace :scenario_documents do
  desc "Diagnóstico de salud de documentos en escenarios"
  task health_check: :environment do
    puts "\n" + "=" * 80
    puts "📊 REPORTE DE SALUD: ESCENARIOS Y DOCUMENTOS"
    puts "=" * 80

    target_scenarios = [13, 14, 15, 16, 17, 18]
    total_duplicates = 0

    target_scenarios.each do |scenario_id|
      scenario = TransactionScenario.find_by(id: scenario_id)
      unless scenario
        puts "\n❌ Scenario #{scenario_id} no encontrado"
        next
      end

      docs = scenario.scenario_documents
      party_types = docs.pluck(:party_type).uniq
      
      puts "\n📋 SCENARIO #{scenario.id}: #{scenario.name}"
      puts "-" * 80
      puts "  📊 Total documentos: #{docs.count}"
      puts "  👥 Tipos de parte únicos: #{party_types.join(', ')}"

      # Detectar duplicados (mismo documento, mismo party_type)
      duplicates = docs.group_by { |d| [d.document_type_id, d.party_type] }
                       .select { |_, group| group.count > 1 }

      if duplicates.any?
        total_duplicates += duplicates.values.flatten.count - duplicates.count
        puts "\n  ⚠️  DUPLICADOS ENCONTRADOS: #{duplicates.keys.count} tipos de documento"
        
        duplicates.each do |(doc_type_id, p_type), group|
          doc_name = DocumentType.find(doc_type_id).name
          puts "     📄 #{doc_name} (ID: #{doc_type_id}), party_type '#{p_type}': #{group.count} registros"
          
          group.sort_by(&:created_at).each_with_index do |d, i|
            status = i == group.size - 1 ? "✅ NUEVO" : "🗑️  OBSOLETO"
            puts "        [#{status}] ID: #{d.id}, created: #{d.created_at.strftime('%Y-%m-%d %H:%M')}, only_principal: #{d.only_for_principal?}"
          end
        end
      else
        puts "\n  ✅ Sin duplicados detectados"
      end
    end

    puts "\n" + "=" * 80
    if total_duplicates > 0
      puts "🎯 RECOMENDACIONES:"
      puts "1. Ejecuta: rails scenario_documents:synchronize_party_types"
      puts "2. Ejecuta: rails scenario_documents:detect_duplicates"
      puts "3. Haz un backup: rails db:backup:create"
      puts "4. Ejecuta: rails scenario_documents:cleanup_duplicates"
    else
      puts "✨ EL SISTEMA ESTÁ LIMPIO. No se requieren acciones de limpieza."
    end
    puts "=" * 80
  end

  desc "Detecta documentos duplicados que serán eliminados"
  task detect_duplicates: :environment do
    target_scenarios = [13, 15, 16, 17, 18] # Excluyendo 14 que ya fue refactorizado, o incluyéndolo si es necesario
    
    puts "\n🔍 DETECTANDO DUPLICADOS CANDIDATOS A ELIMINACIÓN"
    puts "=" * 60
    
    total_to_delete = 0

    target_scenarios.each do |scenario_id|
      scenario = TransactionScenario.find_by(id: scenario_id)
      next unless scenario

      puts "\nScenario #{scenario.id}: #{scenario.name}"
      
      duplicates = scenario.scenario_documents
                          .group_by { |d| [d.document_type_id, d.party_type] }
                          .select { |_, group| group.count > 1 }
      
      duplicates.each do |key, group|
        # Mantener el más reciente, eliminar el resto
        sorted = group.sort_by(&:created_at)
        to_keep = sorted.last
        to_delete = sorted[0...-1]
        
        puts "  📄 DocType #{key[0]} (#{key[1]}): Mantener ID #{to_keep.id}, Eliminar #{to_delete.count}"
        total_to_delete += to_delete.count
      end
    end

    puts "\n" + "=" * 60
    puts "🗑️  TOTAL DOCUMENTOS A ELIMINAR: #{total_to_delete}"
    puts "=" * 60
  end

  desc "Sincroniza los party_types antiguos al nuevo estándar"
  task synchronize_party_types: :environment do
    puts "\n🔄 SINCRONIZANDO TIPOS DE PARTE EN DOCUMENTOS"
    puts "=" * 80

    # Mapeo de conversión: antiguo => nuevo
    mapping = {
      "copropietario" => "copropietario_principal",
      "vendedor"      => "copropietario_principal", 
      "dueño"         => "copropietario_principal",
      "propietario"   => "copropietario_principal"
    }

    scenarios = [13, 14, 15, 16, 17, 18]
    total_updated = 0

    scenarios.each do |id|
      # Solo actualizar si el escenario existe
      next unless TransactionScenario.exists?(id)
      
      mapping.each do |old_type, new_type|
        docs = ScenarioDocument.where(transaction_scenario_id: id, party_type: old_type)
        count = docs.count
        
        if count > 0
          puts "  Scen #{id}: Actualizando #{count} docs de '#{old_type}' a '#{new_type}'"
          docs.update_all(party_type: new_type)
          total_updated += count
        end
      end
    end

    puts "\n✅ Sincronización completada: #{total_updated} documentos actualizados"
    puts "=" * 80
  end

  desc "Elimina documentos duplicados (DESTRUCTIVO)"
  task cleanup_duplicates: :environment do
    puts "\n" + "=" * 80
    puts "🧹 INICIANDO LIMPIEZA DE DOCUMENTOS DUPLICADOS"
    puts "=" * 80
    puts "⚠️  ASEGÚRATE DE TENER UN BACKUP ANTES DE CONTINUAR"
    puts "⚠️  Esta acción eliminará registros de la base de datos permanentemente"
    puts "=" * 80
    print "¿Estás seguro? Escribe 'yes' para confirmar: "
    
    confirmation = STDIN.gets.chomp
    unless confirmation == 'yes'
      puts "❌ Cancelado por el usuario"
      exit
    end

    target_scenarios = [13, 15, 16, 17, 18, 14]
    total_deleted = 0

    ActiveRecord::Base.transaction do
      target_scenarios.each do |scenario_id|
        scenario = TransactionScenario.find_by(id: scenario_id)
        next unless scenario

        puts "\n📋 SCENARIO #{scenario.id}: #{scenario.name}"
        
        # Agrupar por la clave única que define un duplicado
        duplicates = scenario.scenario_documents
                            .group_by { |d| [d.document_type_id, d.party_type] }
                            .select { |_, group| group.count > 1 }

        if duplicates.empty?
          puts "   ✅ Sin duplicados"
          next
        end

        duplicates.each do |(doc_type_id, p_type), group|
          doc_name = DocumentType.find(doc_type_id)&.name || "Unknown"
          puts "   📄 #{doc_name} (#{p_type}) - #{group.count} registros"

          # Ordenar por fecha de creación: el último es el más nuevo (el correcto)
          sorted_group = group.sort_by(&:created_at)
          
          # El último se queda, todos los anteriores se van
          to_keep = sorted_group.last
          to_delete = sorted_group[0...-1]

          puts "     ✨ Manteniendo ID: #{to_keep.id} (created: #{to_keep.created_at.strftime('%F %T')})"
          
          to_delete.each do |doc|
            puts "     🗑️  Eliminando ID: #{doc.id} (created: #{doc.created_at.strftime('%F %T')})"
            doc.destroy!
            total_deleted += 1
          end
        end
      end
    end

    puts "\n" + "=" * 80
    puts "✅ LIMPIEZA COMPLETADA"
    puts "   Documentos eliminados: #{total_deleted}"
    puts "=" * 80
  end
  
  desc "Reporte SQL de documentos"
  task report_sql: :environment do
    puts "Generando query para análisis..."
    sql = <<-SQL
      SELECT 
        ts.id as scenario_id,
        ts.name as scenario_name,
        sd.document_type_id,
        dt.name as doc_name,
        sd.party_type,
        COUNT(*) as count,
        string_agg(sd.id::text, ', ') as ids
      FROM scenario_documents sd
      JOIN transaction_scenarios ts ON ts.id = sd.transaction_scenario_id
      JOIN document_types dt ON dt.id = sd.document_type_id
      WHERE ts.id IN (13, 14, 15, 16, 17, 18)
      GROUP BY 1, 2, 3, 4, 5
      HAVING COUNT(*) > 1
      ORDER BY ts.id, dt.name;
    SQL
    
    results = ActiveRecord::Base.connection.execute(sql)
    results.each do |row|
      puts "Scenario #{row['scenario_id']} | #{row['doc_name']} | #{row['party_type']} | Count: #{row['count']} | IDs: #{row['ids']}"
    end
  end
end