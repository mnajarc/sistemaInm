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
  before_save :set_completed_at, if: -> { status_changed? && completed? }
  before_save :set_converted_at, if: -> { status_changed? && converted? }

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
    owner_name = general_conditions['owner_or_representative_name']
    Client.find_or_create_by!(name: owner_name) do |c|
      c.email = general_conditions['owner_email'] || "temp_#{SecureRandom.hex(4)}@pending.com"
      c.phone = general_conditions['owner_phone'] if general_conditions['owner_phone'].present?
    end
  end

  def find_or_create_property!(client)
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
    return false if converted? || business_transaction.present? || !valid_for_conversion?

    Rails.logger.info "═" * 100
    Rails.logger.info "✅ INICIANDO CONVERSIÓN"
    Rails.logger.info "═" * 100

    begin
      ActiveRecord::Base.transaction do
        client = find_or_create_client!
        property = find_or_create_property!(client)
        transaction = create_business_transaction!(client, property)
        
        co_owners_count = acquisition_details['co_owners_count']&.to_i || 1
        build_transaction_co_owners!(transaction, client, co_owners_count)
        
        update!(
          status: :converted,
          converted_at: Time.current,
          client: client,
          property: property,
          business_transaction: transaction
        )
        
        Rails.logger.info "✅ CONVERSIÓN COMPLETADA"
        Rails.logger.info "   BT: #{transaction.id} | Property: #{property.id} | Client: #{client.id}"
        Rails.logger.info "═" * 100
        
        transaction
      end
    rescue StandardError => e
      Rails.logger.error "❌ ERROR: #{e.class.name}: #{e.message}"
      errors.add(:base, "Error: #{e.message}")
      false
    end
  end

  # ============================================================
  # MÉTODOS PRIVADOS - GENERACIÓN DE IDENTIFICADORES
  # ============================================================
  private

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

  def extract_operation_code
    return 'X' if operation_type_id.blank?
    op_type = OperationType.find_by(id: operation_type_id)
    return 'X' unless op_type
    
    case op_type.name.to_s.downcase
    when /venta/i, /sale/i then 'V'
    when /renta/i, /rent/i then 'R'
    when /traspaso/i then 'T'
    when /permuta/i then 'P'
    when /arrendamiento/i then 'A'
    else 'X'
    end
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
    
    create_required_documents!(bt, scenario) if scenario
    Rails.logger.info "✅ BT creada (ID: #{bt.id})"
    bt
  end

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

  def create_required_documents!(business_transaction, scenario)
    return unless scenario.present?
    Rails.logger.info "📋 Creando documentos para: #{scenario.name}"
    
    scenario.scenario_documents.each do |doc|
      parties = doc.party_type == 'ambos' ? ['oferente', 'adquiriente'] : [doc.party_type]
      parties.each do |party|
        DocumentSubmission.create!(
          business_transaction: business_transaction,
          document_type: doc.document_type,
          party_type: party,
          notes: "Documento requerido: #{scenario.name}"
        )
      end
    end
    
    create_marital_status_documents(business_transaction)
    create_mortgage_documents(business_transaction) if has_mortgage?
  end

  def create_marital_status_documents(business_transaction)
    civil_status = general_conditions['civil_status']
    return unless civil_status == 'casado'
    
    marriage_regime_id = general_conditions['marriage_regime_id']
    regime = MarriageRegime.find_by(id: marriage_regime_id)
    return unless regime
    
    case regime.name.downcase
    when /separaci[oó]n.*bienes/i
      add_document_if_exists(business_transaction, 'escritura_separacion_bienes', 'oferente')
    when /mancomunad|sociedad.*conyugal/i
      add_document_if_exists(business_transaction, 'consentimiento_conyuge', 'oferente')
      add_document_if_exists(business_transaction, 'acta_matrimonio', 'oferente')
    end
  end

  def create_mortgage_documents(business_transaction)
    add_document_if_exists(business_transaction, 'estado_cuenta_hipoteca', 'oferente')
    add_document_if_exists(business_transaction, 'carta_no_adeudo', 'oferente')
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
      'heirs_count' => acquisition_details['heirs_count'],
      'all_living' => acquisition_details['all_living'],
      'deceased_count' => acquisition_details['deceased_count'],
      'has_judicial_sentence' => acquisition_details['has_judicial_sentence'],
      'has_notarial_deed' => acquisition_details['has_notarial_deed']
    }.compact
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
end
