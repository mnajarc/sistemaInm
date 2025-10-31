# db/seeds/fix_transaction_scenarios.rb
# Script para corregir TransactionScenarios
# 1. Guardar nombre actual en display_name
# 2. Convertir name a snake_case

def slugify(text)
  text.unicode_normalize(:nfd)
      .gsub(/[\u0300-\u036f]/, '')     # Quitar acentos
      .downcase
      .strip
      .gsub(/[^a-z0-9\s-]/, '')        # Solo alfanuméricos
      .gsub(/\s+/, '_')                # Espacios → _
      .gsub(/_+/, '_')                 # Múltiples _ → uno
end

puts "\n" + "=" * 80
puts "CORRIGIENDO TRANSACTION SCENARIOS"
puts "=" * 80

total = TransactionScenario.count
puts "\n📊 Total a procesar: #{total}"

correcciones = 0
sin_cambios = 0

TransactionScenario.find_each do |ts|
  # Paso 1: Guardar el nombre actual como display_name
  if ts.display_name.blank?
    ts.update_column(:display_name, ts.name)
    puts "  📝 #{ts.id}: display_name generado: '#{ts.name}'"
  end
  
  # Paso 2: Convertir name a snake_case
  nuevo_name = slugify(ts.name)
  
  if ts.name != nuevo_name
    puts "  ✓ #{ts.id}: '#{ts.name}' → '#{nuevo_name}'"
    ts.update_column(:name, nuevo_name)
    correcciones += 1
  else
    sin_cambios += 1
  end
end

puts "\n" + "=" * 80
puts "RESULTADO:"
puts "  ✅ Corregidos: #{correcciones}"
puts "  ⊘  Sin cambios: #{sin_cambios}"
puts "  📊 Total procesado: #{total}"
puts "=" * 80 + "\n"
