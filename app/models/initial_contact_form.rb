# app/models/initial_contact_form.rb
class InitialContactForm < ApplicationRecord
  # ============================================================
  # RELACIONES
  # ============================================================
  belongs_to :agent # , class_name: 'User'
  belongs_to :client, optional: true
  belongs_to :property, optional: true
  belongs_to :business_transaction, optional: true
  belongs_to :property_acquisition_method, optional: true
  belongs_to :operation_type, optional: true
  belongs_to :contract_signer_type, optional: true

  has_one :acquisition_suggestion, class_name: 'AcquisitionMethodSuggestion', dependent: :nullify

  # ============================================================
  # ENUMS (Rails 8.0 syntax)
  # ============================================================
  enum :status, {
    draft: 0,              # Borrador (guardado parcial)
    completed: 1,          # Completado (listo para convertir)
    converted: 2,          # Convertido a BusinessTransaction
    archived: 3            # Archivado (no se convirtió)
  }, default: :draft
  
  enum :form_source, {
    web: 0,
    mobile: 1,
    paper: 2,
    phone: 3
  }, default: :web
  
  # ============================================================
  # VALIDACIONES
  # ============================================================
  validates :agent_id, presence: true
  validates :status, presence: true
  
  # Validaciones condicionales según el estado
  with_options if: :completed? do
    validate :general_conditions_complete
    validate :property_info_complete
  end
 
  validate :ensure_operation_type_present, if: :completed?
  validate :ensure_acquisition_method_present, if: :completed?

 
  # ============================================================
  # SCOPES
  # ============================================================
  scope :pending_conversion, -> { where(status: :completed, business_transaction_id: nil) }
  scope :by_agent, ->(agent_id) { where(agent_id: agent_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }

  scope :with_owner_name, ->(name) {
    where("general_conditions->>'owner_or_representative_name' ILIKE ?", "%#{name}%")
  }

  scope :by_state, ->(state) {
    where("acquisition_details->>'state' = ?", state)
  }

  scope :by_acquisition_method, ->(method_id) {
    where(property_acquisition_method_id: method_id)
  }

  scope :with_active_mortgage, -> {
    where("current_status->>'has_active_mortgage' = ?", 'true')
  }

  scope :pending_documents, -> {
    completed.where.not(status: :converted)
  }  

  attr_accessor :auto_generated_identifier
  
  before_save :generate_folio_if_missing
  # before_save :generate_property_identifier_if_blank # ← NUEVO
  before_save :generate_identifier_if_blank

  
  validate :validate_acquisition_method_requirements, if: -> { completed? }
   
  # ============================================================
  # CALLBACKS
  # ============================================================
  before_save :set_completed_at, if: -> { status_changed? && completed? }
  before_save :set_converted_at, if: -> { status_changed? && converted? }
  
  # ============================================================
  # MÉTODOS PÚBLICOS
  # ============================================================
   def acquisition_method_display
    return unless property_acquisition_method
    property_acquisition_method.name
  end
  
  def requires_clarification?
    property_acquisition_method&.requires_heirs? || 
    property_acquisition_method&.requires_judicial_sentence?
  end
  
  def suggest_new_acquisition_method!(name, legal_basis)
    AcquisitionMethodSuggestion.create!(
      user: agent.user,
      initial_contact_form: self,
      suggested_name: name,
      legal_basis: legal_basis
    )
  end
  
  def generate_property_identifier(operation_type, property_name)
    sanitized_name = property_name
      .strip
      .downcase
      .gsub(/[áéíóú]/, 'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u')
      .gsub(/[^a-z0-9\s-]/, '')
      .gsub(/\s+/, '_')
      .gsub(/-+/, '_')
      .gsub(/^_|_$/, '')
    
    "#{operation_type}_#{sanitized_name}"
  end
  
  # ═══════════════════════════════════════════════════════════════════════════
  # BÚSQUEDA/CREACIÓN INTELIGENTE DE PROPERTY
  # ═══════════════════════════════════════════════════════════════════════════

  # Buscar Property existente por dirección normalizada
  def find_existing_property
    return nil unless property_info['street'].present? && 
                      property_info['exterior_number'].present? &&
                      acquisition_details['state'].present?

    # Normalizar datos para búsqueda (sin espacios, minúsculas, sin caracteres especiales)
    street_normalized = normalize_for_search(property_info['street'])
    exterior_normalized = normalize_for_search(property_info['exterior_number'])
    state_normalized = normalize_for_search(acquisition_details['state'])
    
    Rails.logger.info "🔍 Buscando propiedad: #{street_normalized}-#{exterior_normalized}-#{state_normalized}"
    
    # Buscar por coincidencia de dirección en scope del usuario
    Property.where(user_id: agent.user_id)
            .where(
              "LOWER(REGEXP_REPLACE(street, '[^a-zA-Z0-9]', '', 'g')) = ? AND 
              LOWER(REGEXP_REPLACE(exterior_number, '[^a-zA-Z0-9]', '', 'g')) = ? AND
              LOWER(REGEXP_REPLACE(state, '[^a-zA-Z0-9]', '', 'g')) = ?",
              street_normalized,
              exterior_normalized,
              state_normalized
            ).first
  end

  # Normalizar string para búsqueda (remover espacios y caracteres especiales)
  def normalize_for_search(text)
    text.to_s.downcase.gsub(/[^a-z0-9]/, '')
  end

  # Generar identificador único de oportunidad
  def generate_opportunity_identifier
    return property_human_identifier if property_human_identifier.present?
    
    # ═══════════════════════════════════════════════════════════════
    # IDENTIFICADOR MIXTO: Cliente + Propiedad + Fecha
    # Formato: V-PEREZ-Insurgentes-1500-20251123
    # ═══════════════════════════════════════════════════════════════
    
    # 1. OPERACIÓN - Código desde operation_type
    operation_code = if operation_type.present?
                      case operation_type.name.downcase
                      when 'venta', 'sale' then 'V'
                      when 'renta', 'rent' then 'R'
                      when 'traspaso' then 'T'
                      when 'permuta' then 'P'
                      else 'X'
                      end
                    else
                      'X'
                    end
    
    # 2. CLIENTE - Primer apellido (hasta 10 caracteres)
    owner_name = general_conditions['owner_or_representative_name'].to_s
    
    # Extraer primer apellido (asume formato: "Nombre Apellido1 Apellido2")
    name_parts = owner_name.strip.split(/\s+/)
    
    # Si tiene al menos 2 palabras, segunda es apellido
    # Si solo tiene 1 palabra, usa esa
    last_name = if name_parts.length >= 2
                name_parts[1]  # ✅ Segundo elemento = primer apellido
                else
                name_parts[0]  # ✅ Solo hay un nombre, usar primero
                end
    
    # Limpiar apellido (sin acentos, sin caracteres especiales, max 10 chars)
    last_name_clean = I18n.transliterate(last_name.to_s)  # ✅ Asegurar que sea String
                        .gsub(/[^a-zA-Z0-9]/, '')
                        .upcase
                        .slice(0, 10)

    # 3. PROPIEDAD - Calle (hasta 12 caracteres para no hacer muy largo)
    street_clean = I18n.transliterate(property_info['street'].to_s)
                    .gsub(/[^a-zA-Z0-9]/, '')
    
    # 4. NÚMERO - Exterior
    exterior = property_info['exterior_number'].to_s.gsub(/[^a-zA-Z0-9]/, '')
    
    # 5. FECHA - YYYYMMDD
    date_str = Date.current.strftime('%Y%m%d')
    
    # 6. CONSTRUIR IDENTIFICADOR
    # Formato: V-PEREZ-Insurgentes-1500-20251123
    identifier = [
      operation_code,
      last_name_clean,
      street_clean,
      exterior,
      date_str
    ].join('-')
    
    # 7. VERIFICAR UNICIDAD (agregar sufijo si existe)
    counter = 1
    base_identifier = identifier
    
    while InitialContactForm.exists?(property_human_identifier: identifier)
      identifier = "#{base_identifier}-#{counter}"
      counter += 1
    end
    
    Rails.logger.info "🏷️ Identificador mixto generado: #{identifier}"
    Rails.logger.info "   Operación: #{operation_code}"
    Rails.logger.info "   Cliente: #{last_name_clean}"
    Rails.logger.info "   Propiedad: #{street_clean}-#{exterior}"
    Rails.logger.info "   Fecha: #{date_str}"
    
    identifier
  end



  # Convertir a BusinessTransaction
  def convert_to_transaction!
    # Validaciones de estado
    if converted?
      errors.add(:base, "Este formulario ya fue convertido")
      return false
    end
    
    if business_transaction.present?
      errors.add(:base, "Ya existe una transacción asociada")
      return false
    end
    
    unless valid_for_conversion?
      errors.add(:base, "El formulario no cumple los requisitos para conversión")
      return false
    end
    
    # Logging inicial
    Rails.logger.info "=" * 80
    Rails.logger.info "🔄 INICIANDO CONVERSIÓN DE FORMULARIO"
    Rails.logger.info "=" * 80
    Rails.logger.info "   ID: ##{id}"
    Rails.logger.info "   Folio: #{initial_contact_folio}"
    Rails.logger.info "   Identificador: #{property_human_identifier}"
    Rails.logger.info "   Propietario: #{general_conditions['owner_or_representative_name']}"
    Rails.logger.info "   Método adquisición: #{property_acquisition_method&.name}"
    Rails.logger.info "   Agente: #{agent.user.name} (#{agent.email})"
    Rails.logger.info "=" * 80
    
    # Transacción atómica
    ActiveRecord::Base.transaction do
      # 1. Crear/encontrar cliente
      client = find_or_create_client!
      Rails.logger.info "✅ Cliente: #{client.name} (ID: #{client.id})"
      
      # 2. Crear propiedad
      property = find_or_create_property!(client)
      Rails.logger.info "✅ Propiedad: #{property.title} (ID: #{property.id})"
      
      # 3. Crear transacción de negocio
      transaction = create_business_transaction!(client, property)
      Rails.logger.info "✅ BusinessTransaction creada (ID: #{transaction.id})"
      
      # 4. Crear copropietarios
      create_co_owners!(transaction)
      Rails.logger.info "✅ Copropietarios creados: #{co_owners_count}"
      
      # 5. Actualizar estado del formulario
      update!(
        status: :converted,
        converted_at: Time.current,
        client: client,
        property: property,
        business_transaction: transaction
      )
      
      Rails.logger.info "=" * 80
      Rails.logger.info "✅ CONVERSIÓN COMPLETADA EXITOSAMENTE"
      Rails.logger.info "   BusinessTransaction ID: #{transaction.id}"
      Rails.logger.info "   Property ID: #{property.id}"
      Rails.logger.info "   Client ID: #{client.id}"
      Rails.logger.info "=" * 80
      
      # Retornar la transacción creada
      transaction
    end

  # ═══════════════════════════════════════════════════════════════════
  # MANEJO DE ERRORES ESPECÍFICOS
  # ═══════════════════════════════════════════════════════════════════

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "=" * 80
    Rails.logger.error "❌ ERROR DE VALIDACIÓN - Formulario ##{id}"
    Rails.logger.error "=" * 80
    Rails.logger.error "   Modelo que falló: #{e.record.class.name}"
    Rails.logger.error "   ID del registro: #{e.record.id rescue 'nuevo registro'}"
    Rails.logger.error "   Errores:"
    e.record.errors.full_messages.each do |msg|
      Rails.logger.error "     • #{msg}"
    end
    Rails.logger.error "=" * 80
    
    errors.add(:base, "Validación falló: #{e.record.errors.full_messages.to_sentence}")
    false

  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "=" * 80
    Rails.logger.error "❌ ERROR DE DUPLICADO - Formulario ##{id}"
    Rails.logger.error "=" * 80
    Rails.logger.error "   Mensaje: #{e.message}"
    Rails.logger.error "=" * 80
    
    errors.add(:base, "Ya existe un registro con estos datos. Por favor revise la información.")
    false

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "=" * 80
    Rails.logger.error "❌ REGISTRO NO ENCONTRADO - Formulario ##{id}"
    Rails.logger.error "=" * 80
    Rails.logger.error "   Mensaje: #{e.message}"
    Rails.logger.error "=" * 80
    
    errors.add(:base, "No se encontró un registro requerido para la conversión.")
    false

  rescue StandardError => e
    Rails.logger.error "=" * 80
    Rails.logger.error "❌ ERROR INESPERADO - Formulario ##{id}"
    Rails.logger.error "=" * 80
    Rails.logger.error "   Tipo: #{e.class.name}"
    Rails.logger.error "   Mensaje: #{e.message}"
    Rails.logger.error "   Backtrace:"
    e.backtrace.first(10).each do |line|
      Rails.logger.error "     #{line}"
    end
    Rails.logger.error "=" * 80
    
    errors.add(:base, "Error del sistema. Por favor contacte al administrador (Ref: #{id})")
    false
  end
  

def valid_for_conversion?
  # 1. Debe estar en estado completed
  return false unless completed?
  
  # 2. Debe tener condiciones generales con nombre del propietario
  return false unless general_conditions.present? && 
                      general_conditions['owner_or_representative_name'].present?
  
  # 3. Debe tener método de adquisición
  return false unless property_acquisition_method_id.present?
  
  # 4. Debe tener tipo de operación
  return false unless operation_type_id.present?
  
  # 5. Debe tener acquisition_details con datos básicos
  # (TU FORMULARIO USA acquisition_details, NO property_info)
  return false unless acquisition_details.present? && 
                      acquisition_details['state'].present? &&
                      acquisition_details['land_use'].present? &&
                      acquisition_details['co_owners_count'].present?
  
  true
end

# Método auxiliar para debugging
def conversion_requirements_status
  {
    completed: completed?,
    has_owner_name: general_conditions['owner_or_representative_name'].present?,
    has_acquisition_method: property_acquisition_method_id.present?,
    has_operation_type: operation_type_id.present?,
    has_state: acquisition_details['state'].present?,
    has_land_use: acquisition_details['land_use'].present?,
    has_co_owners_count: acquisition_details['co_owners_count'].present?
  }
end


 
  # Verificar si está listo para conversión
  
  # Obtener método de adquisición legible
  def acquisition_method_display
    methods = {
      'compra_directa' => 'Compra directa',
      'herencia' => 'Herencia',
      'donacion' => 'Donación',
      'adjudicacion' => 'Adjudicación',
      'prescripcion' => 'Prescripción adquisitiva',
      'dacion_pago' => 'Dación en pago',
      'permuta' => 'Permuta',
      'otro' => 'Otro'
    }
    methods[general_conditions['property_acquisition_method']] || 'No especificado'
  end
  
  # Verificar si es herencia
  def is_inheritance?
    general_conditions['property_acquisition_method'] == 'herencia' ||
    inheritance_info['is_inheritance'] == true
  end
  
  # Verificar si tiene copropietarios
  def has_co_owners?
    (property_info['co_owners_count'] || 1) > 1
  end
  
  # Obtener número de copropietarios
  def co_owners_count
    property_info['co_owners_count'] || 1
  end
  
  # Verificar si califica para exención ISR
  def qualifies_for_tax_exemption?
    tax_exemption['qualifies_for_exemption'] == true
  end
  
  # Porcentaje de completitud
  def completion_percentage
    total_fields = 6 # 6 secciones principales
    completed_sections = 0
    
    completed_sections += 1 if general_conditions.present? && general_conditions.any?
    completed_sections += 1 if property_info.present? && property_info.any?
    completed_sections += 1 if inheritance_info.present? && inheritance_info.any?
    completed_sections += 1 if current_status.present? && current_status.any?
    completed_sections += 1 if tax_exemption.present? && tax_exemption.any?
    completed_sections += 1 if promotion_preferences.present? && promotion_preferences.any?
    
    ((completed_sections.to_f / total_fields) * 100).round(0)
  end
  

  # ============================================================
  # MÉTODOS PRIVADOS
  # ============================================================
  
  private
  def generate_identifier_if_blank
    if property_human_identifier.blank? && 
      property_info['street'].present? && 
      property_info['exterior_number'].present? &&
      operation_type_id.present?
      
      self.property_human_identifier = generate_opportunity_identifier
      Rails.logger.info "💾 Auto-generando identificador: #{property_human_identifier}"
    end
  end


  def ensure_operation_type_present
    if operation_type_id.blank?
      errors.add(:operation_type, "debe estar especificado para completar el formulario")
    end
  end

  def ensure_acquisition_method_present
    if property_acquisition_method_id.blank?
      errors.add(:property_acquisition_method, "debe estar especificado para completar el formulario")
    end
  end
  

  # ============================================================
  # GENERACIÓN AUTOMÁTICA DE IDENTIFICADOR
  # ============================================================
 
  def extract_street(address)
    return nil if address.blank?
    # Lógica simple para extraer calle
    parts = address.split(',').first
    parts&.strip
  end

  def extract_municipality(state)
    # Mapeo básico estado → municipio principal
    {
      'CDMX' => 'Benito Juárez',
      'Jalisco' => 'Guadalajara',
      'Nuevo León' => 'Monterrey'
    }[state]
  end 

  def generate_property_identifier_if_blank
    return if property_human_identifier.present?
    return unless new_record?
    
    self.auto_generated_identifier = true
    
    # MEJOR: usar name en lugar de display_name si no existe
    operation = operation_type&.display_name || 
                operation_type&.name || 
                "Operación"
    
    owner = general_conditions['owner_or_representative_name']&.strip
    
    if owner.present?
      self.property_human_identifier = "#{operation} - #{owner}"
    else
      # Usar folio si existe para mejor tracking
      folio = initial_contact_folio || Time.current.strftime('%d%m%Y-%H%M')
      self.property_human_identifier = "#{operation} - Folio #{folio}"
    end
    
    Rails.logger.info "🏷️  Auto-generando identificador: #{property_human_identifier}"
  end

    
  def generate_folio_if_missing
    return if initial_contact_folio.present?
    return unless agent.present? && agent.user.present?
    initials = extract_initials_from_name(agent.user.name || agent.user.email)
    date = (created_at || Time.current)
    self.initial_contact_folio = generate_contact_folio(initials, date)
  end


  def generate_contact_folio(initials, date)
    date_str = date.strftime('%d%m%y')
    base_folio = "#{initials}#{date_str}"
    
    last_folio = InitialContactForm
      .where("initial_contact_folio LIKE ?", "#{base_folio}%")
      .maximum('initial_contact_folio')
    
    sequence = if last_folio.present?
                (last_folio.split('_').last.to_i + 1).to_s.rjust(2, '0')
              else
                '01'
              end
    
    "#{base_folio}_#{sequence}"
  end


  
  
  def validate_acquisition_method_requirements
    return unless property_acquisition_method.present?
    
    if property_acquisition_method.requires_heirs? && 
       acquisition_details['heirs_count'].blank?
      errors.add(:base, "El método #{property_acquisition_method.name} requiere información de herederos")
    end
  end

  def extract_initials_from_name(full_name)
    # Si es email (contiene @), usar primera parte como fallback
    if full_name.include?('@')
      return full_name.split('@').first.upcase[0..2]
    end
    
    # Separar por espacios y tomar primera letra de cada parte
    parts = full_name.strip.split(/\s+/)
    
    case parts.length
    when 1
      # Solo un nombre: tomar primeras 3 letras
      parts[0].upcase[0..2]
    when 2
      # Nombre + Apellido: primera letra de cada uno + primera del nombre
      "#{parts[0][0]}#{parts[1][0]}#{parts[0][1]}".upcase
    else
      # Nombre + Apellido Paterno + Apellido Materno
      "#{parts[0][0]}#{parts[1][0]}#{parts[2][0]}".upcase
    end
  end
  
  def set_completed_at
    self.completed_at = Time.current
  end
  
  def set_converted_at
    self.converted_at = Time.current
  end
  
  # Validar que condiciones generales estén completas
  def general_conditions_complete
    # Unificar en UN solo método
    errors.add(:general_conditions, "falta el nombre del propietario") if general_conditions['owner_or_representative_name'].blank?
    errors.add(:acquisition_details, "debe especificar la entidad federativa") if acquisition_details['state'].blank?
    errors.add(:acquisition_details, "debe especificar el uso de suelo") if acquisition_details['land_use'].blank?
    
    # Validar método de adquisición si está en estado completed
    if property_acquisition_method_id.blank?
      errors.add(:base, "debe seleccionar un método de adquisición")
    end
    
    if contract_signer_type_id.blank?
      errors.add(:base, "debe seleccionar quién firmará el contrato")
    end
  end

  
  # Validar que info de propiedad esté completa


  def property_info_complete
    # Los datos están en acquisition_details, NO en property_info
    if acquisition_details['co_owners_count'].blank? || acquisition_details['co_owners_count'].to_i < 1
      errors.add(:base, 'debe especificar número de copropietarios (mínimo 1)')
    end
  end
  
  # Buscar o crear cliente
  def find_or_create_client!
    return client if client.present?
    
    # Extraer datos del formulario
    owner_name = general_conditions['owner_or_representative_name']
    
    # Buscar cliente existente o crear nuevo
    Client.find_or_create_by!(name: owner_name) do |c|
      c.email = general_conditions['owner_email'] || "temp_#{SecureRandom.hex(4)}@pending.com"
      c.phone = general_conditions['owner_phone'] if general_conditions['owner_phone'].present?
    end
  end
  
  # Buscar o crear propiedad

# app/models/initial_contact_form.rb

private

# app/models/initial_contact_form.rb


  # Buscar o crear Property con búsqueda inteligente
  def find_or_create_property!(client)
    # 1. Intentar encontrar propiedad existente por dirección
    existing_property = find_existing_property
    
    if existing_property.present?
      Rails.logger.info "✅ Propiedad ENCONTRADA: ##{existing_property.id} - #{existing_property.address}"
      Rails.logger.info "   Reutilizando propiedad existente para evitar duplicado"
      return existing_property
    end
    
    # 2. Si no existe, crear nueva propiedad
    Rails.logger.info "📍 Creando NUEVA propiedad con dirección: #{full_address}"
    
    state = acquisition_details['state'] || 'CDMX'
    land_use = acquisition_details['land_use'] || 'habitacional'
    
    Property.create!(
      # Relaciones
      user: agent.user,
      property_type: determine_property_type,
      
      # Dirección completa (campo legacy)
      address: full_address,
      
      # Dirección desagregada (DESDE property_info)
      street: property_info['street'] || '[Pendiente]',
      exterior_number: property_info['exterior_number'] || 'S/N',
      interior_number: property_info['interior_number'],
      neighborhood: property_info['neighborhood'] || '[Pendiente]',
      city: property_info['city'] || state,
      municipality: property_info['municipality'] || '[Pendiente]',
      state: state,
      postal_code: property_info['postal_code'] || '00000',
      country: property_info['country'] || 'México',
      
      # Precio
      price: property_info['asking_price']&.to_f&.positive? ? property_info['asking_price'].to_f :
            property_info['estimated_price']&.to_f&.positive? ? property_info['estimated_price'].to_f :
            1.0,
      
      # Características físicas
      bedrooms: property_info['bedrooms']&.to_i || 0,
      bathrooms: property_info['bathrooms']&.to_f || 0,
      built_area_m2: property_info['built_area_m2']&.to_f&.positive? ? property_info['built_area_m2'].to_f : 1.0,
      lot_area_m2: property_info['lot_area_m2']&.to_f&.positive? ? property_info['lot_area_m2'].to_f : 1.0,
      parking_spaces: 0,
      year_built: property_info['acquisition_date']&.to_date&.year || Time.current.year,
      
      # Amenidades (valores por defecto)
      furnished: false,
      pets_allowed: false,
      elevator: false,
      balcony: false,
      terrace: false,
      garden: false,
      pool: false,
      security: false,
      gym: false,
      
      # Textos
      title: generate_property_title,
      description: generate_property_description,
      
      # Información de contacto
      contact_phone: general_conditions['owner_phone'],
      contact_email: general_conditions['owner_email'],
      
      # Uso del suelo
      has_extensions: current_status['has_extensions'] == 'true',
      land_use: land_use,
      
      # Notas internas
      internal_notes: compile_property_notes,
      
      # Fechas
      available_from: Date.current,
      published_at: nil
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ Error creando Property desde InitialContactForm ##{id}:"
    Rails.logger.error "   Errores: #{e.record.errors.full_messages.join(', ')}"
    raise
  end

  # Método auxiliar: Dirección completa para campo legacy
  def full_address
    parts = [
      property_info['street'],
      "Núm. #{property_info['exterior_number']}",
      property_info['interior_number'].present? ? "Int. #{property_info['interior_number']}" : nil,
      property_info['neighborhood'],
      "C.P. #{property_info['postal_code']}",
      property_info['municipality'],
      acquisition_details['state'],
      property_info['country']
    ].compact
    
    parts.join(', ')
  end

  # Método auxiliar: Compilar notas internas
  def compile_property_notes
    notes = []
    notes << "📋 Creado desde formulario de contacto inicial ##{id}"
    notes << "🏷️ Identificador de oportunidad: #{property_human_identifier}"
    notes << "👤 Agente: #{agent.user.name} (#{agent.user.email})"
    notes << "📅 Fecha de captura: #{created_at.strftime('%d/%m/%Y %H:%M')}"
    notes << ""
    
    # Advertencias sobre datos pendientes
    if property_info['asking_price'].blank? && property_info['estimated_price'].blank?
      notes << "⚠️ PENDIENTE: Actualizar precio (valor por defecto asignado)"
    end
    
    if property_info['built_area_m2'].blank? || property_info['lot_area_m2'].blank?
      notes << "⚠️ PENDIENTE: Actualizar áreas construida y de terreno"
    end
    
    # Notas del agente si existen
    if agent_notes.present?
      notes << ""
      notes << "📝 Notas del agente:"
      notes << agent_notes
    end
    
    notes.join("\n")
  end


  # Generar título de propiedad automáticamente
  def generate_property_title
    type = general_conditions['domicile_type']&.humanize || 'Inmueble'
    price = property_info['asking_price']&.to_f || property_info['estimated_price']&.to_f || 0
    
    if price > 0
      price_formatted = "$#{(price / 1_000_000.0).round(1)}M"
      "#{type} en venta #{price_formatted}"
    else
      "#{type} en venta"
    end
  end


  
  # Generar descripción de propiedad automáticamente
  def generate_property_description
    parts = []
    
    # Tipo y ubicación
    type = general_conditions['domicile_type']&.humanize || 'Inmueble'
    address = property_info['address'] || 'zona residencial'
    parts << "#{type} ubicado en #{address}"
    
    # Características
    bedrooms = property_info['bedrooms'].to_i
    bathrooms = property_info['bathrooms'].to_f
    built_area = property_info['built_area_m2'].to_f
    
    features = []
    features << "#{bedrooms} recámaras" if bedrooms > 0
    features << "#{bathrooms} baños" if bathrooms > 0
    features << "#{built_area}m² de construcción" if built_area > 0
    
    parts << features.join(', ') if features.any?
    
    # Información de copropietarios
    if has_co_owners?
      parts << "Propiedad con #{co_owners_count} copropietarios"
    end
    
    # Régimen matrimonial
    if general_conditions['civil_status'] == 'casado'
      regime = general_conditions['marriage_regime']&.humanize || 'matrimonial'
      parts << "Régimen: #{regime}"
    end
    
    # Información adicional relevante
    if is_inheritance?
      parts << "⚠️ Propiedad adquirida por herencia"
    end
    
    if property_info['has_improvements']
      parts << "Cuenta con ampliaciones/remodelaciones"
    end
    
    # Descripción final
    description = parts.join('. ') + '.'
    description += "\n\n📋 Información capturada desde formulario de contacto inicial el #{Date.current.strftime('%d/%m/%Y')}."
    description += "\n👤 Agente: #{agent.email}"
    
    description
  end
  
  # Determinar tipo de propiedad
  def determine_property_type
    domicile_type = general_conditions['domicile_type']
    
    type_mapping = {
      'casa_habitacion' => 'house',
      'departamento' => 'apartment',
      'terreno' => 'land',
      'local_comercial' => 'commercial',
      'bodega' => 'warehouse',
      'oficina' => 'office'
    }
    
    property_type_name = type_mapping[domicile_type] || 'house'
    PropertyType.find_by(name: property_type_name) || PropertyType.first
  end
  
  # Crear BusinessTransaction
  def create_business_transaction!(client, property)
    BusinessTransaction.create!(
      listing_agent: agent.user,
      current_agent: agent.user,
      offering_client: client,
      property: property,
      operation_type: OperationType.find_by(name: 'sale') || OperationType.first,
      business_status: BusinessStatus.find_by(name: 'available') || BusinessStatus.first,
      price: property_info['asking_price'] || property.price || 0,
      start_date: Date.current,
      notes: compile_notes
    )
  end
  
  # Crear copropietarios
  def create_co_owners!(transaction)
    return unless has_co_owners?
    
    # Calcular porcentaje por copropietario
    percentage_each = (100.0 / co_owners_count).round(2)
    
    # Crear copropietario principal (el del formulario)
    transaction.business_transaction_co_owners.create!(
      client: transaction.offering_client,
      person_name: general_conditions['owner_or_representative_name'],
      percentage: percentage_each,
      role: 'propietario',
      active: true
    )
    
    # Si hay más copropietarios, crear placeholders
    remaining_count = co_owners_count - 1
    if remaining_count > 0
      remaining_count.times do |i|
        transaction.business_transaction_co_owners.create!(
          person_name: "Copropietario #{i + 2} - Por definir",
          percentage: percentage_each,
          role: 'copropietario',
          active: true
        )
      end
    end
  end
  
  # Compilar notas de todas las secciones
  def compile_notes
    notes = []
    
    notes << "=== FORMULARIO DE CONTACTO INICIAL ==="
    notes << "Completado: #{completed_at&.strftime('%d/%m/%Y')}"
    notes << "Agente: #{agent.email}"
    notes << ""
    
    if is_inheritance?
      notes << "⚠️ HERENCIA - Requiere atención especial"
      notes << "Herederos: #{inheritance_info['heirs_count']}"
      notes << "Tipo sucesión: #{inheritance_info['succession_type']}"
      notes << ""
    end
    
    if current_status['has_active_mortgage']
      notes << "💰 HIPOTECA ACTIVA"
      notes << "Saldo: $#{current_status['mortgage_balance']}"
      notes << "Banco: #{property_info['mortgage_bank']}"
      notes << ""
    end
    
    if qualifies_for_tax_exemption?
      notes << "✅ Califica para exención ISR"
      notes << ""
    end
    
    if agent_notes.present?
      notes << "Observaciones del agente:"
      notes << agent_notes
    end
    
    notes.join("\n")
  end
end
