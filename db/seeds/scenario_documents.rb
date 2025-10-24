# db/seeds/scenario_documents.rb
# Script completo para asociar 161 documentos a los 6 escenarios de transacción
# Agrupados por categoría funcional: Identidad, Propiedad, Financieros, Legales, PLD

puts "\n🔄 Asociando documentos requeridos a escenarios de transacción..."
puts "=" * 80

# Helper para buscar DocumentType de forma flexible
def find_doc_type(name)
  DocumentType.find_by('name ILIKE ?', "%#{name}%")
end

# Helper para crear ScenarioDocument con control de duplicados
def associate_document(scenario, doc_type_name, party, category, required: true)
  doc_type = find_doc_type(doc_type_name)
  
  if doc_type.nil?
    puts "  ⚠️  No existe: #{doc_type_name}"
    return nil
  end
  
  existing = ScenarioDocument.find_by(
    transaction_scenario: scenario,
    document_type: doc_type,
    party_type: party
  )
  
  if existing
    puts "  ↪️  Ya existe: #{doc_type.name} (#{party}) [#{category}]"
    return existing
  end
  
  sd = ScenarioDocument.create!(
    transaction_scenario: scenario,
    document_type: doc_type,
    party_type: party,
    required: required,
    notes: "Categoría: #{category}"
  )
  
  puts "  ✅ #{doc_type.name} (#{party}) [#{category}]"
  sd
end

# =============================================================================
# ESCENARIO 1: VENTA POR COMPRA DIRECTA (25 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 1: Venta por Compra Directa"
puts "-" * 80

escenario_venta_directa = TransactionScenario.find_by(name: 'Venta por Compra Directa')

if escenario_venta_directa
  count = 0
  
  # OFERENTE (Vendedor) - 14 documentos
  puts "\n  👤 OFERENTE (Vendedor):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_venta_directa, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (4)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_venta_directa, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_venta_directa, 'Escritura pública', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_venta_directa, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_venta_directa, 'Boleta predial', 'oferente', 'Propiedad')
  
  # Financieros (3)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_venta_directa, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_venta_directa, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_venta_directa, 'Opinión de cumplimiento SAT', 'oferente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_venta_directa, 'Acta de matrimonio', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_venta_directa, 'Poder notarial', 'oferente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_venta_directa, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Comprador) - 11 documentos
  puts "\n  👤 ADQUIRIENTE (Comprador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_venta_directa, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'RFC', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_venta_directa, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  
  # Financieros (4)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_venta_directa, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_venta_directa, 'Constancia de situación fiscal', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_venta_directa, 'Carta de preaprobación de crédito', 'adquiriente', 'Financieros', required: false)
  count += 1 if associate_document(escenario_venta_directa, 'Comprobante de ingresos', 'adquiriente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_venta_directa, 'Acta de matrimonio', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_venta_directa, 'Poder notarial', 'adquiriente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_venta_directa, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/25"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# ESCENARIO 2: VENTA POR HERENCIA (25 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 2: Venta por Herencia"
puts "-" * 80

escenario_herencia = TransactionScenario.find_by(name: 'Venta por Herencia')

if escenario_herencia
  count = 0
  
  # OFERENTE (Heredero vendedor) - 15 documentos
  puts "\n  👤 OFERENTE (Heredero vendedor):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_herencia, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (3)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_herencia, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_herencia, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_herencia, 'Boleta predial', 'oferente', 'Propiedad')
  
  # Legales - Herencia (5)
  puts "    ⚖️  Legales - Herencia:"
  count += 1 if associate_document(escenario_herencia, 'Acta de defunción', 'oferente', 'Legales')
  count += 1 if associate_document(escenario_herencia, 'Testamento', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_herencia, 'Declaratoria de herederos', 'oferente', 'Legales')
  count += 1 if associate_document(escenario_herencia, 'Adjudicación notarial', 'oferente', 'Legales')
  count += 1 if associate_document(escenario_herencia, 'Acta de nacimiento', 'oferente', 'Legales')
  
  # Financieros (2)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_herencia, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_herencia, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_herencia, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Comprador) - 10 documentos
  puts "\n  👤 ADQUIRIENTE (Comprador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_herencia, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'RFC', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_herencia, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  
  # Financieros (3)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_herencia, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_herencia, 'Constancia de situación fiscal', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_herencia, 'Comprobante de ingresos', 'adquiriente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_herencia, 'Acta de matrimonio', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_herencia, 'Poder notarial', 'adquiriente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_herencia, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/25"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# ESCENARIO 3: RENTA LOCAL COMERCIAL (28 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 3: Renta Local Comercial"
puts "-" * 80

escenario_local = TransactionScenario.find_by(name: 'Renta Local Comercial')

if escenario_local
  count = 0
  
  # OFERENTE (Arrendador) - 15 documentos
  puts "\n  👤 OFERENTE (Arrendador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_local, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (5)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_local, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_local, 'Escritura pública', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_local, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_local, 'Boleta predial', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_local, 'Licencia de uso de suelo comercial', 'oferente', 'Propiedad')
  
  # Financieros (3)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_local, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_local, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_local, 'Opinión de cumplimiento SAT', 'oferente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_local, 'Acta constitutiva', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_local, 'Poder notarial', 'oferente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_local, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Arrendatario comercial) - 13 documentos
  puts "\n  👤 ADQUIRIENTE (Arrendatario):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_local, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'RFC', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_local, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  
  # Financieros (4)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_local, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_local, 'Comprobante de ingresos', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_local, 'Referencias comerciales', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_local, 'Constancia de situación fiscal', 'adquiriente', 'Financieros')
  
  # Legales (4)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_local, 'Acta constitutiva', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_local, 'Poder notarial', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_local, 'Carta de no antecedentes penales', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_local, 'Referencias personales', 'adquiriente', 'Legales')
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_local, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/28"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# ESCENARIO 4: RENTA BODEGA INDUSTRIAL (29 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 4: Renta Bodega Industrial"
puts "-" * 80

escenario_bodega = TransactionScenario.find_by(name: 'Renta Bodega Industrial')

if escenario_bodega
  count = 0
  
  # OFERENTE (Arrendador) - 16 documentos
  puts "\n  👤 OFERENTE (Arrendador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_bodega, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (6)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_bodega, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_bodega, 'Escritura pública', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_bodega, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_bodega, 'Boleta predial', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_bodega, 'Licencia de uso de suelo industrial', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_bodega, 'Certificado de protección civil', 'oferente', 'Propiedad')
  
  # Financieros (3)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_bodega, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_bodega, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_bodega, 'Opinión de cumplimiento SAT', 'oferente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_bodega, 'Acta constitutiva', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_bodega, 'Poder notarial', 'oferente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_bodega, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Arrendatario industrial) - 13 documentos
  puts "\n  👤 ADQUIRIENTE (Arrendatario):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_bodega, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'RFC', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_bodega, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  
  # Financieros (4)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_bodega, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_bodega, 'Estados financieros', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_bodega, 'Referencias comerciales', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_bodega, 'Constancia de situación fiscal', 'adquiriente', 'Financieros')
  
  # Legales (4)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_bodega, 'Acta constitutiva', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_bodega, 'Poder notarial', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_bodega, 'Póliza de seguro de responsabilidad civil', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_bodega, 'Plan de manejo de residuos', 'adquiriente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_bodega, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/29"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# ESCENARIO 5: RENTA APARTAMENTO (26 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 5: Renta Apartamento"
puts "-" * 80

escenario_apto = TransactionScenario.find_by(name: 'Renta Apartamento')

if escenario_apto
  count = 0
  
  # OFERENTE (Arrendador) - 14 documentos
  puts "\n  👤 OFERENTE (Arrendador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_apto, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (5)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_apto, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_apto, 'Escritura pública', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_apto, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_apto, 'Boleta predial', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_apto, 'Último recibo de mantenimiento', 'oferente', 'Propiedad')
  
  # Financieros (2)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_apto, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_apto, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_apto, 'Acta de matrimonio', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_apto, 'Poder notarial', 'oferente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_apto, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Arrendatario) - 12 documentos
  puts "\n  👤 ADQUIRIENTE (Arrendatario):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_apto, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_apto, 'Acta de nacimiento', 'adquiriente', 'Identidad', required: false)
  
  # Financieros (4)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_apto, 'Comprobante de ingresos', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_apto, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_apto, 'Carta de recomendación laboral', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_apto, 'Constancia de situación fiscal', 'adquiriente', 'Financieros', required: false)
  
  # Legales (3)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_apto, 'Referencias personales', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_apto, 'Aval solidario', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_apto, 'Carta de no antecedentes penales', 'adquiriente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_apto, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/26"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# ESCENARIO 6: RENTA CASA HABITACIONAL (28 documentos)
# =============================================================================

puts "\n📋 ESCENARIO 6: Renta Casa Habitacional"
puts "-" * 80

escenario_casa = TransactionScenario.find_by(name: 'Renta Casa Habitacional')

if escenario_casa
  count = 0
  
  # OFERENTE (Arrendador) - 15 documentos
  puts "\n  👤 OFERENTE (Arrendador):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_casa, 'Identificación oficial', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'CURP', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'RFC', 'oferente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'Comprobante de domicilio', 'oferente', 'Identidad')
  
  # Propiedad (6)
  puts "    🏠 Propiedad:"
  count += 1 if associate_document(escenario_casa, 'Título de propiedad', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_casa, 'Escritura pública', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_casa, 'Certificado de libertad de gravamen', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_casa, 'Boleta predial', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_casa, 'Certificado de uso de suelo habitacional', 'oferente', 'Propiedad')
  count += 1 if associate_document(escenario_casa, 'Contrato de agua', 'oferente', 'Propiedad')
  
  # Financieros (2)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_casa, 'Estado de cuenta bancaria', 'oferente', 'Financieros')
  count += 1 if associate_document(escenario_casa, 'Constancia de situación fiscal', 'oferente', 'Financieros')
  
  # Legales (2)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_casa, 'Acta de matrimonio', 'oferente', 'Legales', required: false)
  count += 1 if associate_document(escenario_casa, 'Poder notarial', 'oferente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_casa, 'Formato de identificación del cliente', 'oferente', 'PLD')
  
  # ADQUIRIENTE (Arrendatario) - 13 documentos
  puts "\n  👤 ADQUIRIENTE (Arrendatario):"
  
  # Identidad (4)
  puts "    📇 Identidad:"
  count += 1 if associate_document(escenario_casa, 'Identificación oficial', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'CURP', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'Comprobante de domicilio', 'adquiriente', 'Identidad')
  count += 1 if associate_document(escenario_casa, 'Acta de nacimiento', 'adquiriente', 'Identidad', required: false)
  
  # Financieros (4)
  puts "    💰 Financieros:"
  count += 1 if associate_document(escenario_casa, 'Comprobante de ingresos', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_casa, 'Estado de cuenta bancaria', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_casa, 'Carta de recomendación laboral', 'adquiriente', 'Financieros')
  count += 1 if associate_document(escenario_casa, 'Constancia de situación fiscal', 'adquiriente', 'Financieros', required: false)
  
  # Legales (4)
  puts "    ⚖️  Legales:"
  count += 1 if associate_document(escenario_casa, 'Referencias personales', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_casa, 'Aval solidario', 'adquiriente', 'Legales')
  count += 1 if associate_document(escenario_casa, 'Carta de no antecedentes penales', 'adquiriente', 'Legales', required: false)
  count += 1 if associate_document(escenario_casa, 'Acta de matrimonio', 'adquiriente', 'Legales', required: false)
  
  # PLD (1)
  puts "    🛡️  PLD:"
  count += 1 if associate_document(escenario_casa, 'Formato de identificación del cliente', 'adquiriente', 'PLD')
  
  puts "\n  📊 Total documentos: #{count}/28"
else
  puts "  ❌ Escenario no encontrado"
end

# =============================================================================
# RESUMEN FINAL
# =============================================================================

puts "\n" + "=" * 80
puts "📊 RESUMEN FINAL"
puts "=" * 80

total_scenarios = TransactionScenario.count
total_documents = ScenarioDocument.count

puts "\n✅ Escenarios de transacción: #{total_scenarios}"
puts "✅ Asociaciones documento-escenario: #{total_documents}"

TransactionScenario.all.each do |scenario|
  oferente_count = scenario.scenario_documents.for_oferente.required.count
  adquiriente_count = scenario.scenario_documents.for_adquiriente.required.count
  total = oferente_count + adquiriente_count
  
  puts "\n  📋 #{scenario.name}:"
  puts "     Oferente: #{oferente_count} docs"
  puts "     Adquiriente: #{adquiriente_count} docs"
  puts "     Total: #{total} docs"
end

puts "\n" + "=" * 80
puts "✅ Proceso completado exitosamente"
puts "=" * 80