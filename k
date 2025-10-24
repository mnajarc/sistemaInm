rails c << EOF

escenario = TransactionScenario.find_by(name: 'Venta por Compra Directa')

# Ejemplo de documentos requeridos para prueba
docs = [
  { type: 'Identificación oficial (INE)',      party: 'oferente' },
  { type: 'CURP',                              party: 'oferente' },
  { type: 'RFC',                               party: 'oferente' },
  { type: 'Título de propiedad',               party: 'oferente' },
  { type: 'Acta de nacimiento',                party: 'adquiriente' }
]

docs.each do |d|
  doc_type = DocumentType.find_by('name ILIKE ?', "%#{d[:type]}%")
  if doc_type
    ScenarioDocument.create!(
      transaction_scenario: escenario,
      document_type: doc_type,
      party_type: d[:party],
      required: true
    )
    puts "✔ Asociado: #{d[:type]} (#{d[:party]})"
  else
    puts "⚠ No existe DocumentType con patrón '#{d[:type]}'"
  end
end

exit
EOF
