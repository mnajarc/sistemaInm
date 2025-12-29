# app/models/initial_contact_form.rb
# VERSIÓN FINAL - COMPLETA Y SIN DUPLICADOS
# Incluye TODO: identificadores, validaciones, documentos, conversión
# Fecha: 2025-12-01 - REVISIÓN CRÍTICA COMPLETADA

class InitialContactForm < ApplicationRecord
  # ============================================================
  # RELACIONES
  # ============================================================
  belongs_to :agent
  belongs_to :client, optional: true
  belongs_to :property, optional: true
  belongs_to :business_transaction, optional: true
  belongs_to :property_acquisition_method, optional: true
  belongs_to :operation_type, optional: true
  belongs_to :contract_signer_type, optional: true
  has_one :acquisition_suggestion, class_name: 'AcquisitionMethodSuggestion', dependent: :nullify

  # ============================================================
  # ENUMS
  # ============================================================
  enum :status, { draft: 0, completed: 1, converted: 2, archived: 3 }, default: :draft
  enum :form_source, { web: 0, mobile: 1, paper: 2, phone: 3 }, default: :web

  # ============================================================
  # VALIDACIONES
  # ============================================================
  validates :agent_id, presence: true
  validates :status, presence: true
  
  with_options if: :completed? do
    validate :general_conditions_complete
    validate :property_info_complete
  end
  
  validate :ensure_operation_type_present, if: :completed?
  validate :ensure_acquisition_method_present, if: :completed?
  validate :validate_acquisition_method_requirements, if: -> { completed? }

  # ============================================================
  # SCOPES
  # ============================================================
  scope :pending_conversion, -> { where(status: :completed, business_transaction_id: nil) }
  scope :by_agent, ->(agent_id) { where(agent_id: agent_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  scope :with_owner_name, ->(name) { where("general_conditions->>'owner_or_representative_name' ILIKE ?", "%#{name}%") }
  scope :by_state, ->(state) { where("acquisition_details->>'state' = ?", state) }
  scope :by_acquisition_method, ->(method_id) { where(property_acquisition_method_id: method_id) }
  scope :with_active_mortgage, -> { where("current_status->>'has_active_mortgage' = ?", 'true') }
  scope :pending_documents, -> { completed.where.not(status: :converted) }

  attr_accessor :auto_generated_identifier

  # ============================================================
  # CALLBACKS - ORDEN CRÍTICO
  # ============================================================
  before_validation :generate_folio_if_missing
  before_validation :generate_opportunity_identifier
  before_validation :generate_opportunity_identifier_if_blank
  before_validation :validate_acquisition_method_details
  before_validation :build_owner_or_representative_name
  before_save :set_completed_at, if: -> { status_changed? && completed? }
  before_save :set_converted_at, if: -> { status_changed? && converted? }
  before_save :auto_generate_opportunity_identifier
  before_save :auto_generate_property_id

  # ============================================================
  # MÉTODOS PÚBLICOS - HELPERS PARA VISTAS
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

  # ✅ HERENCIA - METODO UTILIZADO EN LA VISTA show.html.erb:136
  def is_inheritance?
    general_conditions['property_acquisition_method'] == 'herencia' ||
    inheritance_info['is_inheritance'] == true
  end

  # ✅ COPROPIETARIOS
  def has_co_owners?
    (acquisition_details['co_owners_count']&.to_i || 1) > 1
  end

  def co_owners_count
    acquisition_details['co_owners_count'] || 1
  end

  # ✅ HIPOTECA
  def has_mortgage?
    current_status['has_active_mortgage'] == true ||
    current_status['has_active_mortgage'] == 'true'
  end

  # ✅ IMPUESTOS
  def qualifies_for_tax_exemption?
    tax_exemption['qualifies_for_exemption'] == true
  end

  # ✅ COMPLETITUD
  def completion_percentage
    total_fields = 6
    completed_sections = 0
    
    completed_sections += 1 if general_conditions.present? && general_conditions.any?
    completed_sections += 1 if property_info.present? && property_info.any?
    completed_sections += 1 if inheritance_info.present? && inheritance_info.any?
    completed_sections += 1 if current_status.present? && current_status.any?
    completed_sections += 1 if tax_exemption.present? && tax_exemption.any?
    completed_sections += 1 if promotion_preferences.present? && promotion_preferences.any?
    
    ((completed_sections.to_f / total_fields) * 100).round(0)
  end

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

  def normalize_for_search(text)
    text.to_s.downcase.gsub(/[^a-z0-9]/, '')
  end

  # ============================================================
  # MÉTODOS PÚBLICOS - LÓGICA DE CONVERSIÓN
  # ============================================================

  def detect_transaction_scenario
    return nil unless operation_type.present?
    operation_name = operation_type.name.downcase
    acquisition_code = property_acquisition_method&.code

    scenario_name = case operation_name
    when 'venta', 'sale'
      case acquisition_code
      when 'compraventa', 'compra_directa' then 'Venta por Compra Directa'
      when 'herencia' then 'Venta por Herencia'
      else 'Venta por Compra Directa'
      end
    when 'renta', 'rent', 'arrendamiento'
      land_use_code = acquisition_details['land_use']
      case land_use_code
      when 'COM', 'COM_LOCAL' then 'Renta Local Comercial'
      when 'IND', 'IND_BODEGA' then 'Renta Bodega Industrial'
      when 'HAB', 'HAB_PLURI' then 'Renta Apartamento'
      when 'HAB_UNI' then 'Renta Casa Habitacional'
      else 'Renta Casa Habitacional'
      end
    else nil
    end

    return nil unless scenario_name
    scenario = TransactionScenario.find_by(name: scenario_name)
    Rails.logger.info "✅ Escenario: #{scenario_name}" if scenario
    scenario
  end

  def valid_for_conversion?
    return false unless completed?
    return false unless general_conditions.present? && 
                        general_conditions['owner_or_representative_name'].present?
    return false unless property_acquisition_method_id.present?
    return false unless operation_type_id.present?
    return false unless acquisition_details.present? && 
                        acquisition_details['state'].present? &&
                        acquisition_details['land_use'].present? &&
                        acquisition_details['co_owners_count'].present?
    return false unless property_info.present? &&
                        property_info['street'].present? &&
                        property_info['exterior_number'].present? &&
                        property_info['neighborhood'].present? &&
                        property_info['postal_code'].present? &&
                        property_info['municipality'].present? &&
                        property_info['city'].present?
    true
  end

  

  def find_or_create_client!
    return client if client.present?

    # Limpiar campos (evitar nils y espacios extras)
    first_names = general_conditions['first_names'].to_s.strip.presence || ''
    first_surname = general_conditions['first_surname'].to_s.strip.presence || ''
    second_surname = general_conditions['second_surname'].to_s.strip.presence || ''
    email = general_conditions['owner_email'].to_s.strip.presence
    phone = general_conditions['owner_phone'].to_s.strip.presence
    civil_status = general_conditions['civil_status'].to_s.strip.downcase.presence || 'soltero'

    if email
      # Búsqueda primero
      existing_client = Client.where('LOWER(email) = ?', email.downcase).first
 
      return existing_client if existing_client.present?
      
      # Crear con campos individuales (full_name se calcula automáticamente)
      Client.create!(
        first_names: first_names,
        first_surname: first_surname,
        second_surname: second_surname,
        email: email,
        phone: phone,
        civil_status: civil_status
      )
    else
      # Sin email: crear con email temporal
      Client.create!(
        first_names: first_names,
        first_surname: first_surname,
        second_surname: second_surname,
        phone: phone,
        email: "temp_#{SecureRandom.hex(6)}@sin-correo.local",
        civil_status: civil_status
      )
    end
  rescue ActiveRecord::RecordNotUnique
    Client.find_by!(email: email)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ Error creando cliente: #{e.message}"
    false
  end




  def find_or_create_client_anterior_2!
    return client if client.present?

    # Limpiar espacios en blanco (hay "Hernández " con espacio)
    first_names = general_conditions['first_names'].to_s.strip.presence || ''
    first_surname = general_conditions['first_surname'].to_s.strip.presence || ''
    second_surname = general_conditions['second_surname'].to_s.strip.presence || ''
    email = general_conditions['owner_email'].to_s.strip.presence
    phone = general_conditions['owner_phone'].to_s.strip.presence
    civil_status = general_conditions['civil_status'].to_s.strip.presence || 'soltero'

    if email
      existing_client = Client.find_by(email: email)
      return existing_client if existing_client.present?
      
      Client.create!(
        first_names: first_names,
        first_surname: first_surname,
        second_surname: second_surname,
        email: email,
        phone: phone,
        civil_status: civil_status
      )
    else
      Client.create!(
        first_names: first_names,
        first_surname: first_surname,
        second_surname: second_surname,
        phone: phone,
        email: "temp_#{SecureRandom.hex(6)}@sin-correo.local",
        civil_status: civil_status
      )
    end
  rescue ActiveRecord::RecordNotUnique
    Client.find_by!(email: email)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ Error creando cliente: #{e.message}"
    false
  end
  


  
def find_or_create_client_anterior_1!
  return client if client.present?

  # Los campos ya están SEPARADOS en el formulario ✅
  first_names = general_conditions['first_names'].to_s.strip
  first_surname = general_conditions['first_surname'].to_s.strip
  second_surname = general_conditions['second_surname'].to_s.strip
  email = general_conditions['owner_email'].to_s.strip.presence
  phone = general_conditions['owner_phone'].to_s.strip.presence
  civil_status = general_conditions['civil_status'].to_s.strip

  if email
    # Búsqueda primero - si existe, retorna sin actualizar
    existing_client = Client.find_by(email: email)
    return existing_client if existing_client.present?
    
    # Si no existe, crear con los campos individuales
    # full_name se arma automáticamente en el modelo ✅
    Client.create!(
      first_names: first_names,
      first_surname: first_surname,
      second_surname: second_surname,
      email: email,
      phone: phone,
      civil_status: civil_status
    )
  else
    # Sin email: crear cliente "débil" con email sintético
    Client.create!(
      first_names: first_names,
      first_surname: first_surname,
      second_surname: second_surname,
      phone: phone,
      email: "temp_#{SecureRandom.hex(6)}@sin-correo.local",
      civil_status: civil_status
    )
  end
rescue ActiveRecord::RecordNotUnique
  # Race condition: alguien más acaba de crear con este email
  Client.find_by!(email: email)
end


 def find_or_create_property!(client)
  # Si la propiedad ya existe, retórnala
  return property if property.present?

  # Extraer datos de property_info
  street = property_info['street'].to_s.strip
  exterior = property_info['exterior_number'].to_s.strip
  interior = property_info['interior_number'].to_s.strip
  neighborhood = property_info['neighborhood'].to_s.strip
  postal_code = property_info['postal_code'].to_s.strip
  municipality = property_info['municipality'].to_s.strip
  city = property_info['city'].to_s.strip
  country = property_info['country'].to_s.strip

  # Clave única: calle + exterior + postal_code
  Property.create_or_find_by!(
    street: street,
    exterior_number: exterior,
    postal_code: postal_code
  ) do |property|
    property.interior_number = interior
    property.neighborhood = neighborhood
    property.municipality = municipality
    property.city = city
    property.country = country
    property.client = client
  end
rescue ActiveRecord::RecordNotUnique
  Property.find_by!(street: street, exterior_number: exterior, postal_code: postal_code)
end
 





  def find_or_create_property_anterior_1!(client)
    # Si la propiedad ya existe, retórnala
    return property if property.present?

    # Extraer datos de property_info
    street = property_info['street'].to_s.strip
    exterior = property_info['exterior_number'].to_s.strip
    interior = property_info['interior_number'].to_s.strip
    neighborhood = property_info['neighborhood'].to_s.strip
    postal_code = property_info['postal_code'].to_s.strip
    municipality = property_info['municipality'].to_s.strip
    city = property_info['city'].to_s.strip
    country = property_info['country'].to_s.strip

    # Clave única: calle + exterior + postal_code
    Property.create_or_find_by!(
      street: street,
      exterior_number: exterior,
      postal_code: postal_code
    ) do |property|
      property.interior_number = interior
      property.neighborhood = neighborhood
      property.municipality = municipality
      property.city = city
      property.country = country
      property.client = client
    end
  rescue ActiveRecord::RecordNotUnique
    Property.find_by!(street: street, exterior_number: exterior, postal_code: postal_code)
  end




    



  def find_or_create_property_anterior!(client)
    existing_property = Property.find_by_location(
      property_info['street'],
      property_info['exterior_number'],
      property_info['interior_number'],
      property_info['neighborhood'],
      property_info['municipality'],
      acquisition_details['state']
    )
    
    return existing_property if existing_property.present?

    land_use_code = acquisition_details['land_use'] || 'HAB'
    land_use_record = LandUseType.find_by(code: land_use_code)
    land_use = land_use_record&.property_category || 'otros'
    
    Property.create!(
      user: agent.user,
      property_type: determine_property_type,
      address: full_address,
      street: property_info['street'],
      exterior_number: property_info['exterior_number'],
      interior_number: property_info['interior_number'],
      neighborhood: property_info['neighborhood'],
      city: property_info['city'] || acquisition_details['state'],
      municipality: property_info['municipality'],
      state: acquisition_details['state'],
      postal_code: property_info['postal_code'],
      country: 'México',
      price: property_info['asking_price']&.to_f || 1.0,
      bedrooms: property_info['bedrooms']&.to_i,
      bathrooms: property_info['bathrooms']&.to_f,
      built_area_m2: property_info['built_area_m2']&.to_f,
      lot_area_m2: property_info['lot_area_m2']&.to_f,
      land_use: land_use,
      detailed_land_use: land_use_record&.name || 'No especificado',
      title: generate_property_title,
      description: generate_property_description,
      contact_phone: general_conditions['owner_phone'],
      contact_email: general_conditions['owner_email'],
      internal_notes: compile_property_notes,
      available_from: Date.current
    )
  end





def convert_to_transaction!
  return false if converted? || business_transaction.present?

  Rails.logger.info "🔄 [#{id}] Iniciando conversión a transacción..."

  begin
    ActiveRecord::Base.transaction do
      # 1. Obtener/crear cliente
      client = find_or_create_client!
      raise "❌ No se pudo obtener cliente" unless client.present?

      # 2. Obtener/crear propiedad
      prop = find_or_create_property!(client)
      raise "❌ No se pudo obtener propiedad" unless prop.present?

      # 3. Crear transacción de negocio
      transaction = create_business_transaction!(client, prop)
      raise "❌ No se pudo crear transacción" unless transaction.present?

      # 4. Actualizar formulario
      update!(
        status: :converted,
        converted_at: Time.current,
        client: client,
        property: prop,
        business_transaction: transaction
      )

      Rails.logger.info "✅ [#{id}] Conversión exitosa: TX #{transaction.id}"
      transaction  # ← Retorna la transacción
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ [#{id}] Validación falló: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "❌ [#{id}] Error en conversión: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
end






def convert_to_transaction_anterior!
  return false if converted? || business_transaction.present?

  Rails.logger.info "🔄 [#{id}] Iniciando conversión a transacción..."

  begin
    ActiveRecord::Base.transaction do
      # 1. Obtener/crear cliente
      client = find_or_create_client!
      raise "❌ No se pudo obtener cliente" unless client.present?

      # 2. Obtener/crear propiedad
      prop = find_or_create_property!(client)
      raise "❌ No se pudo obtener propiedad" unless prop.present?

      # 3. Crear transacción de negocio
      transaction = create_business_transaction!(client, prop)
      raise "❌ No se pudo crear transacción" unless transaction.present?

      # 4. Actualizar formulario
      update!(
        status: :converted,
        converted_at: Time.current,
        client: client,
        property: prop,
        business_transaction: transaction
      )

      Rails.logger.info "✅ [#{id}] Conversión exitosa: TX #{transaction.id}"
      transaction  # ← Retorna la transacción
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "❌ [#{id}] Validación falló: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "❌ [#{id}] Error en conversión: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
end






  # ============================================================
  # MÉTODOS PRIVADOS - GENERACIÓN DE IDENTIFICADORES
  # ============================================================
  # protected

  def should_generate_identifier?
    general_conditions['owner_or_representative_name'].present? &&
    property_info['street'].present? &&
    property_info['exterior_number'].present?
  end

  def generate_opportunity_identifier
    return if opportunity_identifier.present?
    
    return unless property_info.present? && 
                 property_info['street'].present? &&
                 property_info['exterior_number'].present? &&
                 acquisition_details.present? &&
                 acquisition_details['state'].present?
    
    state_code = extract_state_code_for_property
    municipality_code = extract_municipality_code
    street_code = extract_full_street_code
    exterior = property_info['exterior_number'].to_s.rjust(5, '0')
    interior = property_info['interior_number'].to_s.rjust(5, '0')
    neighborhood_code = extract_neighborhood_code
    
    base_id = [
      state_code,
      municipality_code,
      neighborhood_code,
      street_code,
      exterior,
      interior
    ].compact.join('-')
    
    counter = 0
    final_id = base_id
    
    while InitialContactForm
      .where(opportunity_identifier: final_id)
      .where.not(id: id)
      .exists?
      counter += 1
      final_id = "#{base_id}-#{counter}"
    end
    
    self.opportunity_identifier = final_id
    self.opportunity_identifier_generated_at = Time.current
    
    Rails.logger.info "✅ Property ID: #{final_id}"
    Rails.logger.info "   Ubicación: #{full_address}"
  end


  # ═══════════════════════════════════════════════════════════════════════
  # NUEVO: Construir nombre completo desde componentes
  # ═══════════════════════════════════════════════════════════════════════
  def build_owner_or_representative_name
    return unless general_conditions.present?

    # Construir nombre completo si no existe
    if general_conditions['owner_or_representative_name'].blank?
      first_names = general_conditions['first_names'].to_s.strip
      first_surname = general_conditions['first_surname'].to_s.strip
      second_surname = general_conditions['second_surname'].to_s.strip

      full_name = [first_names, first_surname, second_surname]
        .compact
        .reject(&:empty?)
        .join(' ')
        .strip

      if full_name.present?
        general_conditions['owner_or_representative_name'] = full_name
      end
    end
  end

  # ════════════════════════════════════════════════════════════════════════════
  # MÉTODO: Auto-generar identificador de oportunidad
  # ════════════════════════════════════════════════════════════════════════════
  def auto_generate_opportunity_identifier
    # Solo generar si:
    # 1. No existe identificador manual (o está vacío)
    # 2. Tenemos los datos necesarios

    return if self.opportunity_identifier.present? && self.opportunity_identifier.strip.length > 0

    # Validar que tenemos datos mínimos
    return unless self.general_conditions.present? && self.property_info.present?

    first_surname = self.general_conditions['first_surname'].to_s.strip
    street = self.property_info['street'].to_s.strip
    exterior = self.property_info['exterior_number'].to_s.strip

    # Solo generar si tenemos estos 3 campos como mínimo
    return unless first_surname.present? && street.present? && exterior.present?

    # Obtener código de operación
    op_code = extract_operation_code

    # Limpiar y procesar datos
    last_name_clean = clean_for_identifier(first_surname).upcase[0..10]  # Max 10 chars
    street_clean = clean_for_identifier(street).upcase[0..15]  # Max 15 chars
    exterior_clean = exterior[0..5]  # Max 5 chars
    interior_clean = self.property_info['interior_number'].to_s.strip[0..3]  # Max 3 chars
    date_str = Date.today.strftime('%Y%m%d')

    # Construir identificador
    # Formato: V-CALDERON-INSURGENTES-1500-301-20251204
    identifier = "#{op_code}-#{last_name_clean}-#{street_clean}-#{exterior_clean}"
    identifier += "-#{interior_clean}" if interior_clean.present?
    identifier += "-#{date_str}"

    self.opportunity_identifier = identifier
    self.auto_generated_identifier = true

    Rails.logger.info "✅ AUTO-GENERATED IDENTIFIER: #{identifier}"
  end





  def extract_full_street_code
    street = property_info['street'].to_s.strip
    return 'STREET' if street.blank?
    
    clean_street = street.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
    
    nomenclaturas = ['AVENIDA', 'AV', 'PASEO', 'CALZADA', 'CALLE', 'BOULEVARD', 
                     'BLVD', 'CIRCUITO', 'PROLONGACION', 'CARRERA', 'PLAZA',
                     'PASAJE', 'CERRADA', 'ANDADOR', 'BOSQUE', 'LOMA', 'LOMAS']
    
    words = clean_street.split(/\s+/).compact
    start_idx = nomenclaturas.include?(words[0]) ? 1 : 0
    
    significant = words[start_idx..-1]&.join('') || 'STREET'
    code = significant.gsub(/[^A-Z0-9]/, '').slice(0, 30).presence || 'STREET'
  end

  def extract_municipality_code
    municipality = property_info['municipality'].to_s.strip
    return 'MUN' if municipality.blank?
    
    clean = municipality.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
      .gsub(/[^A-Z0-9]/, '').slice(0, 8)
    
    (clean || 'MUN').ljust(8, '0')[0..7]
  end



  def extract_state_code_for_property
    state = acquisition_details['state'].to_s.strip
    return 'EDO' if state.blank?
    
    state_map = {
      'Ciudad de México' => 'CDMX', 'Ciudad De México' => 'CDMX', 'CDMX' => 'CDMX',
      'Estado de México' => 'EDOMEX', 'Jalisco' => 'JAL', 'Nuevo León' => 'NL',
      'Guanajuato' => 'GTO', 'Puebla' => 'PUE', 'Veracruz' => 'VER',
      'Sinaloa' => 'SIN', 'Chihuahua' => 'CHIH', 'Coahuila' => 'COAH',
      'Durango' => 'DGO', 'Querétaro' => 'QTO', 'Yucatán' => 'YUC',
      'Quintana Roo' => 'QROO'
    }
    
    state_map[state] || state.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
      .gsub(/[^A-Z0-9]/, '').slice(0, 6)
  end

  def generate_opportunity_identifier_if_blank
    return if opportunity_identifier.present?  # ← AGREGAR ESTO
    
    return unless should_generate_identifier?   # ← Usar el método que ya existe
    generate_opportunity_identifier             # ← LLAMAR AL GENERADOR
  end

  
  # ════════════════════════════════════════════════════════════════════════════
  # HELPER: Extraer código de operación (V, R, T, P, X)
  # ════════════════════════════════════════════════════════════════════════════

  def extract_operation_code
    return 'X' unless self.operation_type.present?

    case self.operation_type.name.to_s.downcase
    when /venta|sale/
      'V'
    when /renta|rental|rent/
      'R'
    when /traspaso/
      'T'
    when /permuta|exchange/
      'P'
    else
      'X'
    end
  rescue
    'X'
  end

  # ════════════════════════════════════════════════════════════════════════════
  # HELPER: Limpiar texto para identificadores (sin acentos, sin especiales)
  # ════════════════════════════════════════════════════════════════════════════
  def clean_for_identifier(text)
    text
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/, '')
      .gsub(/[^a-zA-Z0-9]/, '')
  rescue
    'UNKNOWN'
  end

  def extract_client_code
    name = general_conditions['owner_or_representative_name'].to_s.strip
    return 'XXXX' if name.blank?
    
    clean_name = name
      .downcase
      .gsub(/á|à|ä/, 'a').gsub(/é|è|ë/, 'e').gsub(/í|ì|ï/, 'i')
      .gsub(/ó|ò|ö/, 'o').gsub(/ú|ù|ü/, 'u').gsub(/ñ/, 'n')
      .gsub(/[^a-z0-9\s]/, '').gsub(/\s+/, ' ').strip
    
    parts = clean_name.split(' ')
    return 'XXXX' if parts.empty?
    
    code = if parts.length == 1
             parts[0][0..3]
           elsif parts.length == 2
             parts[0][0] + parts[1][0..2]
           else
             first_surname = parts[1]
             second_char = 'X'
             (2...parts.length).each do |i|
               unless ['de', 'la', 'las', 'los', 'el', 'y'].include?(parts[i])
                 second_char = parts[i][0]
                 break
               end
             end
             parts[0][0] + first_surname[0..2] + second_char
           end
    
    code.upcase.ljust(6, 'X')[0..5]
  end

  def extract_street_code
    street = property_info['street'].to_s.strip
    return 'STREET' if street.blank?
    
    clean_street = street.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
    
    words = clean_street.split(/\s+/).compact
    nomenclaturas = ['AVENIDA', 'AV', 'PASEO', 'CALZADA', 'CALLE', 'BOULEVARD', 
                     'BLVD', 'CIRCUITO', 'PROLONGACION', 'CARRERA', 'PLAZA',
                     'PASAJE', 'CERRADA', 'ANDADOR']
    
    significant_words = nomenclaturas.include?(words[0]) ? words.first(2) : words.first(2)
    code = significant_words.join('').gsub(/[^A-Z0-9]/, '').slice(0, 12)
    
    (code || 'STREET').ljust(12, '0')[0..11]
  end

  def extract_neighborhood_code
    neighborhood = property_info['neighborhood'].to_s.strip
    return 'NEIGH' if neighborhood.blank?
    
    clean = neighborhood.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
      .gsub(/[^A-Z0-9]/, '').slice(0, 8)
    
    (clean || 'NEIGH').ljust(8, '0')[0..7]
  end

  def extract_state_code
    state = acquisition_details['state'].to_s.strip
    return 'EDO' if state.blank?
    
    state_map = {
      'Ciudad de México' => 'CDMX', 'Ciudad De México' => 'CDMX', 'CDMX' => 'CDMX',
      'Estado de México' => 'EDOMEX', 'Jalisco' => 'JAL', 'Nuevo León' => 'NL',
      'Guanajuato' => 'GTO', 'Puebla' => 'PUE', 'Veracruz' => 'VER',
      'Sinaloa' => 'SIN', 'Chihuahua' => 'CHIH', 'Coahuila' => 'COAH',
      'Durango' => 'DGO', 'Querétaro' => 'QTO', 'Yucatán' => 'YUC',
      'Quintana Roo' => 'QROO'
    }
    
    state_map[state] || state.upcase
      .gsub(/á|à|ä/, 'A').gsub(/é|è|ë/, 'E').gsub(/í|ì|ï/, 'I')
      .gsub(/ó|ò|ö/, 'O').gsub(/ú|ù|ü/, 'U').gsub(/ñ/, 'N')
      .gsub(/[^A-Z0-9]/, '').slice(0, 6)
  end

  # ============================================================
  # MÉTODOS PRIVADOS - UTILIDADES
  # ============================================================

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

  def extract_initials_from_name(full_name)
    return full_name.split('@').first.upcase[0..2] if full_name.include?('@')
    
    parts = full_name.strip.split(/\s+/)
    
    case parts.length
    when 1 then parts[0].upcase[0..2]
    when 2 then "#{parts[0][0]}#{parts[1][0]}#{parts[0][1]}".upcase
    else "#{parts[0][0]}#{parts[1][0]}#{parts[2][0]}".upcase
    end
  end

  def set_completed_at
    self.completed_at = Time.current
  end

  def set_converted_at
    self.converted_at = Time.current
  end



# ════════════════════════════════════════════════════════════════════════════
# MÉTODO: Auto-generar y vincular Property ID
# ════════════════════════════════════════════════════════════════════════════
def auto_generate_property_id
  return if property_id.present?  # Si ya está vinculada, no hacer nada
  return unless property_info.present? && acquisition_details.present?

  # Extraer datos de ubicación
  street = property_info['street'].to_s.strip
  exterior = property_info['exterior_number'].to_s.strip
  interior = property_info['interior_number'].to_s.strip
  neighborhood = property_info['neighborhood'].to_s.strip
  municipality = property_info['municipality'].to_s.strip
  state = acquisition_details['state'].to_s.strip

  # Validar mínimo de datos
  return unless street.present? && exterior.present? && municipality.present?

  Rails.logger.info "🔍 BUSCANDO PROPIEDAD: #{street} #{exterior}, #{interior}, #{municipality}"

  # ✅ PASO 1: BUSCAR si ya existe la propiedad
  existing_property = Property.where(
    street: street,
    exterior_number: exterior,
    interior_number: interior,
    neighborhood: neighborhood,
    municipality: municipality
  ).first

  if existing_property.present?
    # ✅ VINCULAR a propiedad existente
    self.property_id = existing_property.id
    Rails.logger.info "✅ PROPERTY LINKED (EXISTENTE): #{existing_property.id} - #{existing_property.address}"
    return
  end

  # ✅ PASO 2: CREAR nueva propiedad si no existe
  begin
    Rails.logger.info "➕ CREANDO NUEVA PROPIEDAD..."

    # ✅ PASO CRÍTICO: Convertir STRING a OBJETO PropertyType
    property_type_name = determine_property_type  # Ej: 'casa', 'otros', etc (STRING)
    
    # Buscar el OBJETO PropertyType correspondiente
    # Si no existe, usar el primer PropertyType disponible como fallback
    property_type_obj = PropertyType.find_by(name: property_type_name) || PropertyType.first
    
    # Si no hay PropertyType en la BD, crear uno temporalmente
    unless property_type_obj
      Rails.logger.warn "⚠️ No hay PropertyType en BD. Creando 'otros'..."
      property_type_obj = PropertyType.create!(name: 'otros', description: 'Otros tipos')
    end
    
    # ✅ DEFINIR VALORES POR DEFECTO PARA CAMPOS OBLIGATORIOS
    default_price = 1.0
    default_area = 1.0
    default_land_use = acquisition_details['land_use'].to_s.presence || 'HAB'

    # ✅ Ahora sí, pasar el OBJETO a Property.create!
    new_property = Property.create!(
      user_id: agent&.user_id,
      property_type: property_type_obj,  # ✅ OBJETO PropertyType, NO STRING
      address: build_property_address(street, exterior, interior, neighborhood, municipality),
      street: street,
      exterior_number: exterior,
      interior_number: interior,
      neighborhood: neighborhood,
      city: property_info['city'].to_s,
      municipality: municipality,
      state: state,
      postal_code: property_info['postal_code'].to_s,
      country: property_info['country'].to_s || 'México',
      
      price: default_price,
      built_area_m2: default_area,
      lot_area_m2: default_area,
      bedrooms: 0,
      bathrooms: 0,
      
      # ✅ Título y Descripción obligatorios
      title: "Propiedad en #{street} #{exterior}",
      description: "Propiedad capturada desde Formulario de Contacto Inicial #{self.opportunity_identifier}",

      land_use: LandUseType.find_by(code: acquisition_details['land_use'].to_s.presence || 'HAB')&.property_category || 'habitacional',
      contact_email: general_conditions['owner_email'].to_s,
      contact_phone: general_conditions['owner_phone'].to_s
    )

    self.property_id = new_property.id
    Rails.logger.info "✅ PROPERTY CREATED (NUEVA): #{new_property.id} - #{new_property.address}"

  rescue ActiveRecord::RecordInvalid => e
    # 🚨 Capturar error de validación específico
    Rails.logger.error "❌ ERROR VALIDACIÓN PROPIEDAD: #{e.message}"
    Rails.logger.error e.record.errors.full_messages.inspect

  rescue StandardError => e
    # ⚠️ NO fallar si hay error al crear propiedad
    Rails.logger.error "⚠️ ERROR CREANDO PROPIEDAD: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    # Continuar sin propiedad (no es crítico)
  end
end



  ############################################

  def determine_property_type
    land_use = acquisition_details['land_use']
    case land_use
    when 'VIVIENDA_UNIFAMILIAR', 'CASA' then 'casa'
    when 'VIVIENDA_MULTIFAMILIAR', 'DEPARTAMENTOS', 'EDIFICIO' then 'apartment'
    when 'LOCAL_COMERCIAL', 'COMERCIO' then 'comercial'
    when 'OFICINA' then 'oficina'
    when 'BODEGA', 'INDUSTRIAL', 'NAVE' then 'industrial'
    when 'TERRENO', 'LOTE' then 'lote'
    when 'ESTACIONAMIENTO' then 'estacionamiento'
    when 'HOTEL', 'MOTEL' then 'hotel'
    else 'otros'
    end
  end




  # ════════════════════════════════════════════════════════════════════════════
  # HELPER: Construir dirección completa
  # ════════════════════════════════════════════════════════════════════════════
  def build_property_address(street, exterior, interior, neighborhood, municipality)
    parts = [street, exterior]
    parts << "Apt/Int: #{interior}" if interior.present?
    parts << neighborhood if neighborhood.present?
    parts << municipality if municipality.present?

    parts.compact.join(', ')
  end



  def generate_property_title
    street = property_info['street'].to_s
    number =  [ property_info['exterior_number'].to_s,
                property_info['interior_number'].to_s ]
                .reject(&:blank?)
                .join('-')
    city = property_info['city'].to_s
    "#{street} #{number} - #{city}"
  end

  def generate_property_description
    desc_parts = []
    
    desc_parts << "**Método:** #{property_acquisition_method.name}" if property_acquisition_method
    desc_parts << "• Hipoteca activa" if current_status['has_active_mortgage'] == 'true'
    desc_parts << "• Condominio" if current_status['is_in_condominium'] == 'true'
    desc_parts << "• Ampliaciones" if current_status['has_extensions'] == 'true'
    desc_parts << "• Remodelaciones" if current_status['has_renovations'] == 'true'
    
    desc_parts.empty? ? 'Propiedad sin características especiales' : desc_parts.join("\n")
  end

  def compile_property_notes
    notes = []
    notes << "📋 Desde ICF ##{id}"
    notes << "🏷️ ID: #{opportunity_identifier}"
    notes << "👤 Agente: #{agent.user.name}"
    notes.join("\n")
  end

  def full_address
    parts = [
      property_info['street'],
      "Núm. #{property_info['exterior_number']}",
      "Int. #{property_info['interior_number']}"
    ]
    
    parts << "Int. #{property_info['interior_number']}" if property_info['interior_number'].present?
    
    parts += [
      property_info['neighborhood'],
      "C.P. #{property_info['postal_code']}",
      property_info['municipality'],
      acquisition_details['state'],
      property_info['country'] || 'México'
    ]
    
    parts.compact.join(', ')
  end

  # ============================================================
  # MÉTODOS PRIVADOS - VALIDACIONES
  # ============================================================

  def general_conditions_complete
    errors.add(:general_conditions, "falta nombre del propietario") if general_conditions['owner_or_representative_name'].blank?
    errors.add(:acquisition_details, "debe especificar estado") if acquisition_details['state'].blank?
    errors.add(:acquisition_details, "debe especificar uso de suelo") if acquisition_details['land_use'].blank?
    errors.add(:base, "debe seleccionar método de adquisición") if property_acquisition_method_id.blank?
    errors.add(:base, "debe seleccionar quién firmará") if contract_signer_type_id.blank?
  end

  def property_info_complete
    if acquisition_details['co_owners_count'].blank? || acquisition_details['co_owners_count'].to_i < 1
      errors.add(:base, 'especifique copropietarios (mínimo 1)')
    end
  end

  def ensure_operation_type_present
    errors.add(:operation_type, "debe estar especificado") if operation_type_id.blank?
  end

  def ensure_acquisition_method_present
    errors.add(:property_acquisition_method, "debe estar especificado") if property_acquisition_method_id.blank?
  end

  def validate_acquisition_method_requirements
    return unless property_acquisition_method.present?
    
    if property_acquisition_method.requires_heirs? && 
       acquisition_details['heirs_count'].blank?
      errors.add(:base, "El método #{property_acquisition_method.name} requiere información de herederos")
    end
  end

  def validate_acquisition_method_details
    method = property_acquisition_method
    return unless method.present? && completed?
    
    case method.code.to_s.upcase
    when 'COMPRAVENTA'
      if acquisition_details['co_owners_count'].blank? || acquisition_details['co_owners_count'].to_i < 1
        errors.add(:acquisition_details, 'requiere número válido de copropietarios')
      end
    when 'HERENCIA'
      if acquisition_details['heirs_count'].blank? || acquisition_details['heirs_count'].to_i < 1
        errors.add(:acquisition_details, 'requiere número válido de herederos')
      end
    when 'DONACION'
      if acquisition_details['donor_name'].blank?
        errors.add(:acquisition_details, 'requiere nombre completo del donante')
      end
    end
  end

  # ============================================================
  # MÉTODOS PRIVADOS - TRANSACCIONES Y DOCUMENTOS
  # ============================================================

  
  
def create_business_transaction_anterior_casi!(client, property)
  raise "Cliente requerido" unless client.present?
  raise "Propiedad requerida" unless property.present?

  BusinessTransaction.create!(
    client: client,
    property: property,
    agent_id: agent_id,
    initial_contact_form: self,
    status: :created,
    # Otros campos según tu modelo
    general_conditions: general_conditions,
    property_info: property_info,
    acquisition_details: acquisition_details
  )
end





  def create_business_transaction_anterior_1!(client, property)
    raise "Cliente requerido" unless client.present?
    raise "Propiedad requerida" unless property.present?

    BusinessTransaction.create!(
      client: client,
      property: property,
      agent_id: agent_id,
      initial_contact_form: self,
      status: :created,
      # Otros campos según tu modelo
      general_conditions: general_conditions,
      property_info: property_info,
      acquisition_details: acquisition_details
    )
  end




  def create_business_transaction!(client, property)
    scenario = detect_transaction_scenario
    
    bt = BusinessTransaction.create!(
      listing_agent_id: agent&.user_id,
      current_agent_id: agent&.user_id,
      offering_client: client,
      property: property,
      operation_type_id: operation_type_id,
      business_status: BusinessStatus.find_by(name: 'prospecto') || BusinessStatus.first,
      transaction_scenario: scenario,
      price: property_info['asking_price'] || property.price || 1,
      commission_percentage: 0,
      start_date: Date.current,
      property_acquisition_method_id: property_acquisition_method_id,
      acquisition_legal_act: property_acquisition_method&.name,
      initial_contact_folio: initial_contact_folio,
      notes: compile_transaction_notes,
      inheritance_details: build_inheritance_details,
      property_status: build_property_status,
      tax_information: build_tax_information,
      legal_representation: build_legal_representation
    )

      create_co_owners!(bt, client)

    create_required_documents!(bt, scenario) if scenario
    Rails.logger.info "✅ BT creada (ID: #{bt.id})"
    bt
  end


  def create_co_owners!(business_transaction, primary_client)
    # Obtener datos de herencia desde acquisition_details
    heirs_count = acquisition_details['heirs_count'].to_i
    civil_status = general_conditions['current_civil_status']
    
    if heirs_count <= 1
      # Un solo propietario (100%)
      BusinessTransactionCoOwner.create!(
        business_transaction: business_transaction,
        client: primary_client,
        percentage: 100,
        person_name: primary_client.full_name,
        role: 'propietario',  # ← Usar role en lugar de ownership_type
        active: true
      )
    else
      # Múltiples herederos (copropietarios)
      percentage_per_heir = 100 / heirs_count
      
      # El cliente principal como heredero #1 (propietario principal)
      BusinessTransactionCoOwner.create!(
        business_transaction: business_transaction,
        client: primary_client,
        percentage: percentage_per_heir,
        person_name: primary_client.full_name,
        role: 'propietario',  # ← Rol principal
        active: true
      )
      
      # Crear placeholders para los otros herederos
      (heirs_count - 1).times do |index|
        BusinessTransactionCoOwner.create!(
          business_transaction: business_transaction,
          client: nil,  # Se asignará después
          percentage: percentage_per_heir,
          person_name: "Heredero #{index + 2}",  # Temporal
          role: 'copropietario',  # ← Rol secundario
          active: true
        )
      end
    end
    
    Rails.logger.info "✅ #{business_transaction.business_transaction_co_owners.count} copropietarios creados"
  end


# app/models/initial_contact_form.rb

def create_required_documents!(business_transaction, scenario)
  return unless scenario.present?
  
  Rails.logger.info "=" * 80
  Rails.logger.info "📋 CREANDO DOCUMENTOS - DEBUG INTENSO"
  Rails.logger.info "Scenario: #{scenario.name} (ID: #{scenario.id})"
  Rails.logger.info "BT ID: #{business_transaction.id}"
  Rails.logger.info "=" * 80
  
  scenario.scenario_documents.each do |scenario_doc|
    doc_name = scenario_doc.document_type.name
    only_principal = scenario_doc.only_for_principal?
    party_type = scenario_doc.party_type
    
    # 🔴 DEBUG CADA DOCUMENTO
    Rails.logger.info "🔍 Doc: #{doc_name}"
    Rails.logger.info "   only_for_principal: #{only_principal} (#{only_principal.class})"
    Rails.logger.info "   party_type: #{party_type.inspect}"
    Rails.logger.info "   DB valores: #{scenario_doc.inspect}"
    
    # Si es solo para principal, crear solo para propietario
    if only_principal
      Rails.logger.info "   ✅ Usando: SOLO PROPIETARIO (only_for_principal=true)"
      target_co_owners = business_transaction.business_transaction_co_owners
                                              .where(role: 'propietario')
    else
      Rails.logger.info "   ❌ Usando: map_party_type_to_co_owners(#{party_type})"
      target_co_owners = map_party_type_to_co_owners(
        business_transaction, 
        party_type
      )
    end
    
    Rails.logger.info "   → Creando para #{target_co_owners.count} copropietarios:"
    target_co_owners.each do |co_owner|
      Rails.logger.info "      - #{co_owner.person_name} (role: #{co_owner.role})"
      
      DocumentSubmission.create!(
        business_transaction: business_transaction,
        business_transaction_co_owner: co_owner,
        document_type: scenario_doc.document_type,
        party_type: scenario_doc.party_type,
        notes: "Documento requerido por escenario: #{scenario.name}"
      )
    end
    Rails.logger.info ""
  end
  
  Rails.logger.info "✅ #{business_transaction.document_submissions.count} documentos creados"
  Rails.logger.info "=" * 80
end








# ✅ NUEVO MÉTODO: Crear copropietarios basado en datos de herencia


  def build_transaction_co_owners!(business_transaction, main_client, co_owners_count)
    percentage = (100.0 / co_owners_count).round(2)
    
    BusinessTransactionCoOwner.create!(
      business_transaction: business_transaction,
      client: main_client,
      person_name: main_client.name,
      percentage: percentage,
      role: 'propietario',
      active: true
    )
    
    (co_owners_count - 1).times do |i|
      BusinessTransactionCoOwner.create!(
        business_transaction: business_transaction,
        client: nil,
        person_name: "Copropietario #{i + 2} - Pendiente",
        percentage: percentage,
        role: 'copropietario',
        active: false
      )
    end
  end


  # Documentos relacionados con estado civil
  def create_marital_status_documents(business_transaction)
    business_transaction.business_transaction_co_owners.each do |co_owner|
      # Obtener estado civil del copropietario
      civil_status = co_owner.civil_status || 'soltero'
      
      case civil_status
      when 'casado', 'unión_libre'
        # Requiere consentimiento del cónyuge
        DocumentSubmission.create!(
          business_transaction: business_transaction,
          business_transaction_co_owner: co_owner,
          document_type: DocumentType.find_by(code: 'consentimiento_conyugal'),
          party_type: 'oferente',
          notes: "Consentimiento requerido: #{civil_status}"
        )
      when 'divorciado'
        # Requiere sentencia de divorcio
        DocumentSubmission.create!(
          business_transaction: business_transaction,
          business_transaction_co_owner: co_owner,
          document_type: DocumentType.find_by(code: 'sentencia_divorcio'),
          party_type: 'oferente',
          notes: "Sentencia de divorcio requerida"
        )
      when 'viudo'
        # Requiere acta de defunción
        DocumentSubmission.create!(
          business_transaction: business_transaction,
          business_transaction_co_owner: co_owner,
          document_type: DocumentType.find_by(code: 'acta_defuncion'),
          party_type: 'oferente',
          notes: "Acta de defunción requerida"
        )
      end
    end
  end

  # Documentos relacionados con hipotecas
  def create_mortgage_documents(business_transaction)
    return unless has_mortgage?
    
    business_transaction.business_transaction_co_owners.each do |co_owner|
      # Carta de liberación del banco
      DocumentSubmission.create!(
        business_transaction: business_transaction,
        business_transaction_co_owner: co_owner,
        document_type: DocumentType.find_by(code: 'carta_liberacion_hipoteca'),
        party_type: 'oferente',
        notes: "Propiedad hipotecada: requiere carta de liberación"
      )
      
      # Avalúo actualizado
      DocumentSubmission.create!(
        business_transaction: business_transaction,
        business_transaction_co_owner: co_owner,
        document_type: DocumentType.find_by(code: 'avaluo_actualizado'),
        party_type: 'oferente',
        notes: "Avalúo actualizado para trámite hipotecario"
      )
    end
  end





  def add_document_if_exists(business_transaction, document_code, party_type)
    document_type = DocumentType.find_by(name: document_code) ||
                   DocumentType.find_by("LOWER(name) = ?", document_code.downcase)
    return unless document_type
    
    DocumentSubmission.create!(
      business_transaction: business_transaction,
      document_type: document_type,
      party_type: party_type,
      status: 'pendiente_solicitud'
    )
  rescue StandardError
    # Documento no encontrado, continuar
  end

  def compile_transaction_notes
    notes = "=== ICF ===\nFolio: #{initial_contact_folio}\n"
    notes += "ID: #{opportunity_identifier}\n"
    notes += "Completado: #{completed_at&.strftime('%d/%m/%Y %H:%M')}\n\n"
    notes += "=== NOTAS ===\n#{agent_notes}" if agent_notes.present?
    notes
  end



  def build_inheritance_details
  return {} unless property_acquisition_method&.code == 'herencia'
  
  {
    'heirs_count' => acquisition_details['heirs_count']&.to_i,
    'all_living' => convert_to_bool(acquisition_details['all_living']),
    'deceased_count' => acquisition_details['deceased_count']&.to_i,
    'all_married' => convert_to_bool(acquisition_details['all_married']),
    'single_heirs_count' => acquisition_details['single_heirs_count']&.to_i,
    'deceased_civil_status' => acquisition_details['deceased_civil_status'],
    'inheritance_from' => acquisition_details['inheritance_from'],
    'inheritance_from_other' => acquisition_details['inheritance_from_other'],
    'parents_were_married' => convert_to_bool(acquisition_details['parents_were_married']),
    'parents_marriage_regime' => acquisition_details['parents_marriage_regime'],
    'has_testamentary_succession' => convert_to_bool(acquisition_details['has_testamentary_succession']),
    'succession_planned_date' => acquisition_details['succession_planned_date'],
    'succession_authority' => acquisition_details['succession_authority'],
    'succession_type' => acquisition_details['succession_type']
  }.reject { |_, v| v.blank? }
end


  def build_property_status
    {
      'has_active_mortgage' => current_status['has_active_mortgage'],
      'mortgage_balance' => current_status['mortgage_balance'],
      'is_in_condominium' => current_status['is_in_condominium'],
      'has_extensions' => current_status['has_extensions'],
      'has_renovations' => current_status['has_renovations'],
      'has_rental_units' => current_status['has_rental_units']
    }.compact
  end

  def build_tax_information
    {
      'first_home_sale' => tax_exemption['first_home_sale'],
      'lived_last_5_years' => tax_exemption['lived_last_5_years'],
      'qualifies_for_exemption' => tax_exemption['qualifies_for_exemption']
    }.compact
  end

  def build_legal_representation
    {
      'owner_name' => general_conditions['owner_or_representative_name'],
      'civil_status' => general_conditions['civil_status'],
      'contract_signer_type' => contract_signer_type&.name
    }.compact
  end

  def map_party_type_to_co_owners(business_transaction, party_type)
    case party_type
    when 'copropietario_principal'
      # Solo el propietario principal (vendedor)
      business_transaction.business_transaction_co_owners.where(role: 'propietario')
    
    when 'copropietario'
      # ✅ FIJO: Todos los PROPIETARIOS (principal + secundarios)
      business_transaction.business_transaction_co_owners
                          .where(role: ['propietario', 'copropietario'])
    
    when 'ambos'
      # Todos los propietarios (principal + secundarios)
      business_transaction.business_transaction_co_owners
    
    when 'adquiriente'
      # El comprador - NOT a co-owner (retorna vacío por ahora)
      []
    
    else
      []
    end
  end


  def convert_to_bool(value)
    return value if [true, false].include?(value)
    value.to_s.strip.downcase == 'true'
  end



end
