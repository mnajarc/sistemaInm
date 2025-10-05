puts "🌱 Iniciando seeds del sistema refactorizado..."

# Cargar todos los seeds modulares
Dir[Rails.root.join("db", "seeds", "*.rb")].sort.each do |file|
  puts "📂 Cargando: #{File.basename(file)}"
  load file
end

puts "\n✅ Seeds completados exitosamente!"
puts "🚀 Sistema completamente configurado sin hardcoding"