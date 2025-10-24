# db/seeds/document_types_complete.rb
# Catálogo completo de tipos de documentos para sistema inmobiliario
# Usando el esquema correcto: metadata para reglas de vigencia

puts "\n🔄 Creando catálogo completo de tipos de documentos..."
puts "=" * 80

# Helper para crear o actualizar DocumentType
def create_or_update_doc_type(name, category, description, metadata_attrs = {})
  doc = DocumentType.find_or_initialize_by(name: name)
  
  # Merge metadata preservando lo existente
  current_metadata = doc.metadata || {}
  new_metadata = current_metadata.merge(metadata_attrs)
  
  doc.assign_attributes(
    display_name: name,
    description: description,
    category: category,
    valid_from: Date.parse('2024-01-01'),  # Fecha desde que existe este tipo de doc en el sistema
    valid_until: nil,  # Sin fecha de fin (vigente indefinidamente)
    is_active: true,
    metadata: new_metadata,
    mandatory: metadata_attrs[:mandatory] || false,
    blocks_transaction: metadata_attrs[:blocks_transaction] || false
  )
  
  if doc.new_record?
    doc.save!
    puts "  ✅ Creado: #{name} [#{category}]"
  else
    doc.save! if doc.changed?
    puts "  ↪️  Existe: #{name} [#{category}]"
  end
  
  doc
end

# =============================================================================
# CATEGORÍA: IDENTIDAD (11 documentos)
# =============================================================================

puts "\n📇 CATEGORÍA: Identidad"
puts "-" * 80

create_or_update_doc_type(
  'Identificación oficial (INE/IFE)',
  'identidad',
  'Credencial para votar vigente emitida por INE/IFE',
  {
    validity_months: 120,  # 10 años desde expedición
    has_expiry: true,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'CURP',
  'identidad',
  'Clave Única de Registro de Población',
  {
    has_expiry: false,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'RFC',
  'identidad',
  'Registro Federal de Contribuyentes',
  {
    has_expiry: false,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Comprobante de domicilio',
  'identidad',
  'Recibo de servicios (luz, agua, teléfono, gas) no mayor a 3 meses',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Acta de nacimiento',
  'identidad',
  'Acta de nacimiento certificada',
  {
    validity_months: 6,  # Certificación vigente 6 meses
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Acta de matrimonio',
  'identidad',
  'Acta de matrimonio certificada',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Acta de defunción',
  'identidad',
  'Acta de defunción certificada para casos de herencia',
  {
    has_expiry: false,
    mandatory: true,  # En escenarios de herencia
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Pasaporte',
  'identidad',
  'Pasaporte vigente para extranjeros',
  {
    validity_months: 12,  # Verificar vigencia al momento de transacción
    has_expiry: true,
    mandatory: true,  # Para extranjeros
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Forma migratoria',
  'identidad',
  'FM2, FM3 o documento migratorio equivalente vigente',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para extranjeros
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Acta constitutiva',
  'identidad',
  'Acta constitutiva de persona moral',
  {
    has_expiry: false,
    mandatory: true,  # Para personas morales
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Poder notarial',
  'identidad',
  'Poder notarial vigente con facultades específicas',
  {
    validity_months: 24,
    has_expiry: true,
    mandatory: true,  # Si se actúa mediante representante
    blocks_transaction: true
  }
)

# =============================================================================
# CATEGORÍA: PROPIEDAD (15 documentos)
# =============================================================================

puts "\n🏠 CATEGORÍA: Propiedad"
puts "-" * 80

create_or_update_doc_type(
  'Título de propiedad',
  'propiedad',
  'Documento que acredita la propiedad del inmueble',
  {
    has_expiry: false,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Escritura pública',
  'propiedad',
  'Escritura pública debidamente inscrita',
  {
    has_expiry: false,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Certificado de libertad de gravamen',
  'propiedad',
  'Certificado que acredita que el inmueble está libre de gravámenes',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Boleta predial',
  'propiedad',
  'Recibo de pago del impuesto predial del año en curso',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Certificado de no adeudo predial',
  'propiedad',
  'Certificado expedido por la autoridad fiscal municipal',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Licencia de uso de suelo comercial',
  'propiedad',
  'Licencia municipal para uso comercial del inmueble',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para locales comerciales
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Licencia de uso de suelo industrial',
  'propiedad',
  'Licencia municipal para uso industrial del inmueble',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para bodegas industriales
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Certificado de uso de suelo habitacional',
  'propiedad',
  'Certificado de uso de suelo para vivienda',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Certificado de protección civil',
  'propiedad',
  'Certificado de cumplimiento de medidas de protección civil',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para bodegas industriales
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Último recibo de mantenimiento',
  'propiedad',
  'Recibo de cuota de mantenimiento de condominio',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Contrato de agua',
  'propiedad',
  'Contrato de servicio de agua potable',
  {
    has_expiry: false,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Plano arquitectónico',
  'propiedad',
  'Planos arquitectónicos del inmueble',
  {
    has_expiry: false,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Avalúo comercial',
  'propiedad',
  'Avalúo comercial realizado por perito autorizado',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Reglamento interno',
  'propiedad',
  'Reglamento interno de condominio o fraccionamiento',
  {
    has_expiry: false,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Certificado de no invasión de área federal',
  'propiedad',
  'Para propiedades cercanas a zona federal marítima',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,  # Solo para zonas costeras
    blocks_transaction: false
  }
)

# =============================================================================
# CATEGORÍA: FINANCIEROS (12 documentos)
# =============================================================================

puts "\n💰 CATEGORÍA: Financieros"
puts "-" * 80

create_or_update_doc_type(
  'Estado de cuenta bancaria',
  'financieros',
  'Estados de cuenta bancarios de los últimos 3 meses',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Constancia de situación fiscal',
  'financieros',
  'Constancia de situación fiscal emitida por SAT',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Opinión de cumplimiento SAT',
  'financieros',
  'Opinión positiva de cumplimiento de obligaciones fiscales',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Comprobante de ingresos',
  'financieros',
  'Recibos de nómina, declaraciones anuales o constancia de ingresos',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Carta de preaprobación de crédito',
  'financieros',
  'Carta de institución financiera con preaprobación de crédito',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Estados financieros',
  'financieros',
  'Estados financieros auditados de persona moral',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para personas morales
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Referencias comerciales',
  'financieros',
  'Cartas de referencia de proveedores o clientes',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Carta de recomendación laboral',
  'financieros',
  'Carta de recomendación del empleador actual',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Declaración anual SAT',
  'financieros',
  'Declaración anual de impuestos del último ejercicio fiscal',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Comprobante de pago de impuestos',
  'financieros',
  'Comprobantes de pago de ISR, IVA u otros impuestos',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Carta de no adeudo bancario',
  'financieros',
  'Carta de institución bancaria confirmando no adeudos',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Comprobante de capacidad económica',
  'financieros',
  'Documento que acredite capacidad económica para la transacción',
  {
    validity_months: 3,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

# =============================================================================
# CATEGORÍA: LEGALES (13 documentos)
# =============================================================================

puts "\n⚖️  CATEGORÍA: Legales"
puts "-" * 80

create_or_update_doc_type(
  'Testamento',
  'legales',
  'Testamento público abierto o cerrado',
  {
    has_expiry: false,
    mandatory: false,  # Solo en herencias
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Declaratoria de herederos',
  'legales',
  'Resolución judicial o notarial que declara herederos',
  {
    has_expiry: false,
    mandatory: true,  # En herencias sin testamento
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Adjudicación notarial',
  'legales',
  'Escritura de adjudicación de herencia',
  {
    has_expiry: false,
    mandatory: true,  # En herencias
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Referencias personales',
  'legales',
  'Cartas de referencia personal de terceros',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Aval solidario',
  'legales',
  'Documentación completa de aval solidario para arrendamiento',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,  # Según políticas de arrendamiento
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Carta de no antecedentes penales',
  'legales',
  'Carta de no antecedentes penales expedida por autoridad competente',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Póliza de seguro de responsabilidad civil',
  'legales',
  'Póliza vigente de seguro de responsabilidad civil',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,  # Para bodegas industriales
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Plan de manejo de residuos',
  'legales',
  'Plan de manejo de residuos para uso industrial',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Carta poder simple',
  'legales',
  'Carta poder simple para trámites menores',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Resolución judicial',
  'legales',
  'Resolución judicial relacionada con el inmueble',
  {
    has_expiry: false,
    mandatory: false,  # Solo si aplica
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Convenio de divorcio',
  'legales',
  'Convenio de divorcio que afecte la propiedad del inmueble',
  {
    has_expiry: false,
    mandatory: false,  # Solo si aplica
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Acta de asamblea',
  'legales',
  'Acta de asamblea de condóminos autorizando operación',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,  # Solo para condominios
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Certificado de no inhabilitación',
  'legales',
  'Certificado de no inhabilitación para ejercer comercio',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

# =============================================================================
# CATEGORÍA: PLD (5 documentos)
# =============================================================================

puts "\n🛡️  CATEGORÍA: PLD (Prevención Lavado Dinero)"
puts "-" * 80

create_or_update_doc_type(
  'Formato de identificación del cliente',
  'pld',
  'Formato de identificación del cliente para cumplimiento PLD',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: true
  }
)

create_or_update_doc_type(
  'Declaración de origen de recursos',
  'pld',
  'Declaración del origen lícito de los recursos',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Cédula de identificación fiscal',
  'pld',
  'Cédula de identificación fiscal expedida por SAT',
  {
    has_expiry: false,
    mandatory: true,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Constancia de CLABE bancaria',
  'pld',
  'Constancia de cuenta bancaria (CLABE interbancaria)',
  {
    validity_months: 6,
    has_expiry: true,
    mandatory: false,
    blocks_transaction: false
  }
)

create_or_update_doc_type(
  'Declaración patrimonial',
  'pld',
  'Declaración patrimonial para operaciones de alto valor',
  {
    validity_months: 12,
    has_expiry: true,
    mandatory: false,  # Solo para operaciones > umbral UMA
    blocks_transaction: false
  }
)

# =============================================================================
# RESUMEN
# =============================================================================

puts "\n" + "=" * 80
puts "📊 RESUMEN DE TIPOS DE DOCUMENTOS"
puts "=" * 80

total = DocumentType.count

puts "\n✅ Total tipos de documentos: #{total}"

categories = DocumentType.group(:category).count
puts "\nPor categoría:"
categories.each do |category, count|
  puts "  #{category.capitalize}: #{count} documentos"
end

puts "\n" + "=" * 80
puts "✅ Catálogo de documentos completado exitosamente"
puts "=" * 80