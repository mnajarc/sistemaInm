# db/seeds/transaction_scenarios.rb (crear archivo)
puts "🔄 Creando escenarios de transacción..."

scenarios = [
  {
    name: 'Venta por Compra Directa',
    category: 'compraventa',
    description: 'Compraventa directa entre particulares sin intermediarios especiales',
    active: true
  },
  {
    name: 'Venta por Herencia',  
    category: 'compraventa',
    description: 'Compraventa derivada de proceso sucesorio o herencia',
    active: true
  },
  {
    name: 'Renta Local Comercial',
    category: 'renta_comercial', 
    description: 'Arrendamiento de local para actividad comercial',
    active: true
  },
  {
    name: 'Renta Bodega Industrial',
    category: 'renta_comercial',
    description: 'Arrendamiento de bodega para uso industrial o almacenamiento',
    active: true
  },
  {
    name: 'Renta Apartamento',
    category: 'renta_habitacional',
    description: 'Arrendamiento de departamento para uso habitacional',
    active: true
  },
  {
    name: 'Renta Casa Habitacional',
    category: 'renta_habitacional', 
    description: 'Arrendamiento de casa unifamiliar para uso habitacional',
    active: true
  }
]

scenarios.each do |attrs|
  scenario = TransactionScenario.find_or_create_by!(name: attrs[:name]) do |s|
    s.attributes = attrs
  end
  puts "  ✅ #{scenario.name}"
end

puts "🏘️  #{TransactionScenario.count} escenarios de transacción creados"
