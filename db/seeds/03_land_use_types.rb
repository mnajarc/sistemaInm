puts "🌱 Creando tipos de uso de suelo..."

# ═══════════════════════════════════════════════════════════════
# CATEGORÍAS PRINCIPALES
# ═══════════════════════════════════════════════════════════════
main_categories = [
  { code: 'HAB', name: 'Habitacional', property_category: 'habitacional', sort_order: 1 },
  { code: 'COM', name: 'Comercial', property_category: 'comercial', sort_order: 2 },
  { code: 'IND', name: 'Industrial', property_category: 'industrial', sort_order: 3 },
  { code: 'MIX', name: 'Mixto', property_category: 'mixto', sort_order: 4 },
  { code: 'AGR', name: 'Agropecuario', property_category: 'otros', sort_order: 5 }
]

main_categories.each do |category|
  LandUseType.find_or_create_by!(code: category[:code]) do |t|
    t.name = category[:name]
    t.property_category = category[:property_category]  # ← MAPEO AQUÍ
    t.category = category[:code].downcase
    t.sort_order = category[:sort_order]
    t.active = true
  end
end

# ═══════════════════════════════════════════════════════════════
# SUBCATEGORÍAS DE HABITACIONAL
# ═══════════════════════════════════════════════════════════════
residential = LandUseType.find_by(code: 'HAB')
residential_subtypes = [
  { code: 'HAB_UNI', name: 'Vivienda Unifamiliar', property_category: 'habitacional', sort_order: 10 },
  { code: 'HAB_PLURI', name: 'Vivienda Plurifamiliar (Departamentos)', property_category: 'habitacional', sort_order: 11 },
  { code: 'HAB_MIX', name: 'Habitacional con Comercio', property_category: 'mixto', sort_order: 12 }
]

residential_subtypes.each do |subtype|
  LandUseType.find_or_create_by!(code: subtype[:code]) do |t|
    t.name = subtype[:name]
    t.property_category = subtype[:property_category]  # ← MAPEO AQUÍ
    t.parent = residential
    t.category = 'residential'
    t.sort_order = subtype[:sort_order]
    t.active = true
  end
end

# ═══════════════════════════════════════════════════════════════
# SUBCATEGORÍAS DE COMERCIAL
# ═══════════════════════════════════════════════════════════════
commercial = LandUseType.find_by(code: 'COM')
commercial_subtypes = [
  { code: 'COM_LOCAL', name: 'Local Comercial', property_category: 'comercial', sort_order: 20 },
  { code: 'COM_CENTRO', name: 'Centro Comercial', property_category: 'comercial', sort_order: 21 },
  { code: 'COM_OFICINA', name: 'Oficinas', property_category: 'comercial', sort_order: 22 },
  { code: 'COM_SERVICIOS', name: 'Servicios Profesionales', property_category: 'comercial', sort_order: 23 }
]

commercial_subtypes.each do |subtype|
  LandUseType.find_or_create_by!(code: subtype[:code]) do |t|
    t.name = subtype[:name]
    t.property_category = subtype[:property_category]  # ← MAPEO AQUÍ
    t.parent = commercial
    t.category = 'commercial'
    t.sort_order = subtype[:sort_order]
    t.active = true
  end
end

puts "✅ #{LandUseType.count} tipos de uso de suelo creados"

# ═══════════════════════════════════════════════════════════════
# VERIFICACIÓN DE MAPEO
# ═══════════════════════════════════════════════════════════════
puts "\n📊 Mapeo de property_category:"
LandUseType.order(:sort_order).each do |land_use|
  puts "   #{land_use.code.ljust(15)} (#{land_use.name.ljust(40)}) → #{land_use.property_category}"
end

puts "\n🎉 Seeds de Land Use Types completados exitosamente!"
