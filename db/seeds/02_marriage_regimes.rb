
puts "🌱 Creando regímenes matrimoniales..."

regimes = [
  {
    name: 'separacion_bienes',
    display_name: 'Separación de Bienes',
    description: 'Cada cónyuge conserva la propiedad y administración de sus bienes',
    sort_order: 1
  },
  {
    name: 'sociedad_conyugal',
    display_name: 'Sociedad Conyugal',
    description: 'Los bienes adquiridos durante el matrimonio pertenecen a ambos',
    sort_order: 2
  }
]

regimes.each do |regime|
  MarriageRegime.find_or_create_by!(name: regime[:name]) do |r|
    r.assign_attributes(regime)
  end
end

puts "✅ #{MarriageRegime.count} regímenes matrimoniales creados"

