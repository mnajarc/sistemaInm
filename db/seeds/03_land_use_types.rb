
puts "🌱 Creando tipos de uso de suelo..."

# Categorías principales
main_categories = {
  'HAB' => 'Habitacional',
  'COM' => 'Comercial',
  'IND' => 'Industrial',
  'MIX' => 'Mixto',
  'AGR' => 'Agropecuario'
}

main_categories.each do |code, name|
  LandUseType.find_or_create_by!(code: code) do |t|
    t.name = name
    t.category = code.downcase
    t.sort_order = main_categories.keys.index(code)
  end
end

# Subcategorías de Habitacional
residential = LandUseType.find_by(code: 'HAB')
residential_subtypes = [
  { code: 'HAB_UNI', name: 'Vivienda Unifamiliar' },
  { code: 'HAB_PLURI', name: 'Vivienda Plurifamiliar (Departamentos)' },
  { code: 'HAB_MIX', name: 'Habitacional con Comercio' }
]

residential_subtypes.each_with_index do |subtype, idx|
  LandUseType.find_or_create_by!(code: subtype[:code]) do |t|
    t.name = subtype[:name]
    t.parent = residential
    t.category = 'residential'
    t.sort_order = idx
  end
end

# Subcategorías de Comercial
commercial = LandUseType.find_by(code: 'COM')
commercial_subtypes = [
  { code: 'COM_LOCAL', name: 'Local Comercial' },
  { code: 'COM_CENTRO', name: 'Centro Comercial' },
  { code: 'COM_OFICINA', name: 'Oficinas' },
  { code: 'COM_SERVICIOS', name: 'Servicios Profesionales' }
]

commercial_subtypes.each_with_index do |subtype, idx|
  LandUseType.find_or_create_by!(code: subtype[:code]) do |t|
    t.name = subtype[:name]
    t.parent = commercial
    t.category = 'commercial'
    t.sort_order = idx
  end
end

puts "✅ #{LandUseType.count} tipos de uso de suelo creados"
puts "\n🎉 Seeds completados exitosamente!"

