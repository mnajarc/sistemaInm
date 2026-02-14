# app/models/initial_contact_form.rb
# REFACTORIZACIÓN FASE 2A
# ✅ Métodos zombie eliminados
# ✅ Callbacks consolidados (11 → 7)
# ✅ StringNormalizer extraído
# ✅ Identificador regenerable si cambian datos
# ✅ Catálogos de BD en lugar de hardcodeo
# Fecha: 2026-02-10

class InitialContactForm < ApplicationRecord
  include FolioGenerator
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
  # CALLBACKS - CONSOLIDADOS (antes eran 11, ahora son 7)
  # ============================================================
  after_initialize :initialize_acquisition_details
  before_validation :ensure_identifiers_generated
  before_validation :validate_acquisition_method_details
  before_save :auto_generate_property_id
  before_save :ensure_co_owners_count_is_integer
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

  def is_inheritance?
    general_conditions['property_acquisition_method'] == 'herencia' ||
    inheritance_info['is_inheritance'] == true
  end

  def has_co_owners?
    (acquisition_details['co_owners_count']&.to_i || 1) > 1
  end

  def co_owners_count
    acquisition_details['co_owners_count'] || 1
  end

  def has_mortgage?
    current_status['has_active_mortgage'] == true ||
    current_status['has_active_mortgage'] == 'true'
  end

  def qualifies_for_tax_exemption?
    tax_exemption['qualifies_for_exemption'] == true
  end

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
  # REGENERACIÓN DE IDENTIFICADOR
  # Permite actualizar el opportunity_identifier cuando cambian
  # datos que lo componen (ej: error en número exterior)
  # ============================================================
  def regenerate_opportunity_identifier!
    self.opportunity_identifier = nil
    self.opportunity_identifier_generated_at = nil
    generate_opportunity_identifier_simple
    save!
  end

  # ============================================================
  # MÉTODOS PÚBLICOS - LÓGICA DE CONVERSIÓN
  # ============================================================

  def detect_transaction_scenario
    return nil unless operation_type.present?

    # Buscar escenario desde catálogos de BD, no hardcodeado
    scenario = find_scenario_from_catalogs
    return scenario if scenario.present?

    # Fallback: buscar por categoría de operación
    scenario = TransactionScenario
      .where(active: true, category: operation_type.name.downcase)
      .first

    Rails.logger.info "✅ Escenario detectado: #{scenario&.name}" if scenario
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

    gc = general_conditions || {}

    first_names    = gc['first_names'].to_s.strip.presence
    first_surname  = gc['first_surname'].to_s.strip.presence
    second_surname = gc['second_surname'].to_s.strip.presence
    email          = gc['owner_email'].to_s.strip.presence
    phone          = gc['owner_phone'].to_s.strip.presence
    civil_status   = gc['civil_status'].to_s.strip.downcase.presence || 'soltero'

    unless email.present?
      Rails.logger.error "❌ [ICF##{id}] Falta email del propietario"
      return false
    end

    unless first_names.present?
      Rails.logger.error "❌ [ICF##{id}] Falta nombre (first_names) del propietario"
      return false
    end

    unless first_surname.present?
      Rails.logger.error "❌ [ICF##{id}] Falta primer apellido (first_surname) del propietario"
      return false
    end

    existing_client = Client.where('LOWER(email) = ?', email.downcase).first
    if existing_client.present?
      Rails.logger.info "✅ [ICF##{id}] Cliente existente encontrado: ID #{existing_client.id}"
      return existing_client
    end

    begin
      new_client = Client.create!(
        first_names:    first_names,
        first_surname:  first_surname,
        second_surname: second_surname,
        email:          email,
        phone:          phone,
        civil_status:   civil_status
      )

      Rails.logger.info "✅ [ICF##{id}] Cliente CREADO: ID #{new_client.id}"
      new_client

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "❌ [ICF##{id}] VALIDACIÓN FALLIDA al crear cliente"
      Rails.logger.error "   Errores: #{e.record.errors.full_messages.join(', ')}"
      false

    rescue StandardError => e
      Rails.logger.error "❌ [ICF##{id}] ERROR INESPERADO: #{e.class} - #{e.message}"
      Rails.logger.error "   #{e.backtrace.first(3).join("\n   ")}"
      false
    end
  end

  def find_or_create_property!(client)
    return property if property.present?

    street = property_info['street'].to_s.strip
    exterior = property_info['exterior_number'].to_s.strip
    interior = property_info['interior_number'].to_s.strip
    neighborhood = property_info['neighborhood'].to_s.strip
    postal_code = property_info['postal_code'].to_s.strip
    municipality = property_info['municipality'].to_s.strip
    city = property_info['city'].to_s.strip
    country = property_info['country'].to_s.strip

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

  def convert_to_transaction!
    return false if converted? || business_transaction.present?

    Rails.logger.info "🔄 [#{id}] Iniciando conversión a transacción..."

    begin
      ActiveRecord::Base.transaction do
        client = find_or_create_client!
        raise "❌ No se pudo obtener cliente" unless client.present?

        prop = find_or_create_property!(client)
        raise "❌ No se pudo obtener propiedad" unless prop.present?

        transaction = create_business_transaction!(client, prop)
        raise "❌ No se pudo crear transacción" unless transaction.present?

        update!(
          status: :converted,
          converted_at: Time.current,
          client: client,
          property: prop,
          business_transaction: transaction
        )

        Rails.logger.info "✅ [#{id}] Conversión exitosa: TX #{transaction.id}"
        transaction
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
  # MÉTODOS PRIVADOS - CALLBACKS CONSOLIDADOS
  # ============================================================
  private

# ============================================================
# MÉTODOS PRIVADOS - GENERACIÓN DE FOLIO
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
    
    # Buscar el último folio con ese prefijo
    last_folio = InitialContactForm
      .where("initial_contact_folio LIKE ?", "#{base_folio}%")
      .maximum(:initial_contact_folio)
    
    sequence = if last_folio.present?
                 last_folio.split('-').last.to_i + 1.to_s.rjust(2, '0')
               else
                 '01'
               end
    
    "#{base_folio}-#{sequence}"
  end

  def extract_initials_from_name(full_name)
    return full_name.split.first.upcase[0..2] if full_name.include?('@')
    
    parts = full_name.strip.split
    case parts.length
    when 1 then parts[0].upcase[0..2]
    when 2 then "#{parts[0][0]}#{parts[1][0]}#{parts[0][1]}".upcase
    else "#{parts[0][0]}#{parts[1][0]}#{parts[2][0]}".upcase
    end
  end



  # Callback consolidado: antes eran 5 before_validation separados
  def ensure_identifiers_generated
    build_owner_or_representative_name
    generate_folio_if_missing
    generate_opportunity_identifier_consolidated
  end

  def generate_opportunity_identifier_consolidated
    # CAMBIO CLAVE: Si cambiaron datos que componen el identificador,
    # regenerar aunque ya exista uno
    if opportunity_identifier.present? && !identifier_source_data_changed?
      return
    end

    if general_conditions_available_for_simple_identifier?
      generate_opportunity_identifier_simple
    end
  end

  # Detecta si cambiaron los datos que componen el identificador
  def identifier_source_data_changed?
    return false unless persisted?

    # Si cambiaron property_info o acquisition_details, regenerar
    property_info_changed? || acquisition_details_changed?
  end

  def property_info_complete_for_full_identifier?
    property_info.present? &&
    property_info['street'].present? &&
    property_info['exterior_number'].present? &&
    acquisition_details.present? &&
    acquisition_details['state'].present?
  end

  def general_conditions_available_for_simple_identifier?
    general_conditions.present? &&
    general_conditions['first_surname'].present? &&
    property_info.present? &&
    property_info['street'].present? &&
    property_info['exterior_number'].present?
  end

  # ============================================================
  # MÉTODOS PRIVADOS - GENERACIÓN DE IDENTIFICADORES
  # ============================================================

  def generate_opportunity_identifier_from_property
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

  def generate_opportunity_identifier_simple
    first_surname = general_conditions['first_surname'].to_s.strip
    street = property_info['street'].to_s.strip
    exterior = property_info['exterior_number'].to_s.strip

    return unless first_surname.present? && street.present? && exterior.present?

    op_code = extract_operation_code

    last_name_clean = StringNormalizer.to_code(first_surname, max_length: 11)
    street_clean = StringNormalizer.to_code(street, max_length: 16)
    exterior_clean = exterior[0..5]
    interior_clean = property_info['interior_number'].to_s.strip[0..3]
    date_str = Date.today.strftime('%Y%m%d')

    identifier = "#{op_code}-#{last_name_clean}-#{street_clean}-#{exterior_clean}"
    identifier += "-#{interior_clean}" if interior_clean.present?
    identifier += "-#{date_str}"

    self.opportunity_identifier = identifier
    self.auto_generated_identifier = true

    Rails.logger.info "✅ AUTO-GENERATED IDENTIFIER: #{identifier}"
  end

  def initialize_acquisition_details
    if self.acquisition_details.blank?
      self.acquisition_details = { 'co_owners_count' => 1 }
    elsif self.acquisition_details['co_owners_count'].blank?
      self.acquisition_details['co_owners_count'] = 1
    end
  end

  def ensure_co_owners_count_is_integer
    if acquisition_details.present? && acquisition_details['co_owners_count'].present?
      acquisition_details['co_owners_count'] = acquisition_details['co_owners_count'].to_i
    end
  end

  def build_owner_or_representative_name
    return unless general_conditions.present?

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



  def set_completed_at
    self.completed_at = Time.current
  end

  def set_converted_at
    self.converted_at = Time.current
  end

  # ============================================================
  # MÉTODOS PRIVADOS - RESOLUCIÓN DE ESCENARIO DESDE CATÁLOGOS
  # ============================================================
  def find_scenario_from_catalogs
    return nil unless operation_type.present?

    normalized_category = operation_type.name.to_s.downcase
      .gsub(/renta|rent|arrendamiento/, 'renta')
      .gsub(/venta|sale/, 'venta')

    scenario = TransactionScenario
      .where(active: true)
      .where("LOWER(category) = ?", normalized_category)
      .first

    return scenario if scenario.present?

    # Fallback por nombre construido
    scenario_name = build_scenario_name(normalized_category, property_acquisition_method&.code.to_s)
    TransactionScenario.find_by(name: scenario_name, active: true) if scenario_name
  end


  def build_scenario_name(op_name, acquisition_code)
    case op_name
    when /venta|sale/
      case acquisition_code
      when 'compraventa', 'compra_directa' then 'Venta por Compra Directa'
      when 'herencia' then 'Venta por Herencia'
      else nil
      end
    when /renta|rent|arrendamiento/
      land_use_code = acquisition_details['land_use']
      case land_use_code
      when 'COM', 'COM_LOCAL' then 'Renta Local Comercial'
      when 'IND', 'IND_BODEGA' then 'Renta Bodega Industrial'
      when 'HAB', 'HAB_PLURI' then 'Renta Apartamento'
      when 'HAB_UNI' then 'Renta Casa Habitacional'
      else 'Renta Casa Habitacional'
      end
    end
  end

  # ============================================================
  # MÉTODOS PRIVADOS - UTILIDADES (StringNormalizer)
  # ============================================================

  def extract_full_street_code
    street = property_info['street'].to_s.strip
    return 'STREET' if street.blank?

    clean_street = StringNormalizer.unaccent(street).upcase

    nomenclaturas = ['AVENIDA', 'AV', 'PASEO', 'CALZADA', 'CALLE', 'BOULEVARD',
                     'BLVD', 'CIRCUITO', 'PROLONGACION', 'CARRERA', 'PLAZA',
                     'PASAJE', 'CERRADA', 'ANDADOR', 'BOSQUE', 'LOMA', 'LOMAS']

    words = clean_street.split(/\s+/).compact
    start_idx = nomenclaturas.include?(words[0]) ? 1 : 0

    significant = words[start_idx..-1]&.join('') || 'STREET'
    significant.gsub(/[^A-Z0-9]/, '').slice(0, 30).presence || 'STREET'
  end

  def extract_municipality_code
    municipality = property_info['municipality'].to_s.strip
    return 'MUN' if municipality.blank?

    StringNormalizer.to_padded_code(municipality, max_length: 8)
  end

  def extract_state_code_for_property
    state = acquisition_details['state'].to_s.strip
    return 'EDO' if state.blank?

    # Usar catálogo mexican_states si está disponible
    mexican_state = MexicanState.find_by(name: state) ||
                    MexicanState.find_by(full_name: state)

    return mexican_state.code if mexican_state.present?

    # Fallback si no se encuentra en catálogo
    StringNormalizer.to_code(state, max_length: 6)
  rescue NameError
    # Si MexicanState no existe como modelo, usar normalización directa
    StringNormalizer.to_code(state, max_length: 6)
  end

  def extract_neighborhood_code
    neighborhood = property_info['neighborhood'].to_s.strip
    return 'NEIGH' if neighborhood.blank?

    StringNormalizer.to_padded_code(neighborhood, max_length: 8)
  end

  def extract_operation_code
    return 'X' unless operation_type.present?

    case operation_type.name.to_s.downcase
    when /venta|sale/          then 'V'
    when /renta|rental|rent/   then 'R'
    when /traspaso/            then 'T'
    when /permuta|exchange/    then 'P'
    else 'X'
    end
  rescue
    'X'
  end

  def clean_for_identifier(text)
    StringNormalizer.to_code(text, max_length: 50)
  end


  def extract_client_code
    name = general_conditions['owner_or_representative_name'].to_s.strip
    return 'XXXX' if name.blank?

    clean_name = StringNormalizer.unaccent(name).downcase.gsub(/\s+/, ' ').strip

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

  def build_property_address(street, exterior, interior, neighborhood, municipality)
    parts = [street, exterior]
    parts << "Apt/Int: #{interior}" if interior.present?
    parts << neighborhood if neighborhood.present?
    parts << municipality if municipality.present?
    parts.compact.join(', ')
  end

  def generate_property_title
    street = property_info['street'].to_s
    number = [property_info['exterior_number'].to_s,
              property_info['interior_number'].to_s]
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
      "Núm. #{property_info['exterior_number']}"
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
  # MÉTODOS PRIVADOS - AUTO GENERACIÓN DE PROPERTY ID
  # ============================================================

  def auto_generate_property_id
    return if property_id.present?
    return unless property_info.present? && acquisition_details.present?

    street = property_info['street'].to_s.strip
    exterior = property_info['exterior_number'].to_s.strip
    interior = property_info['interior_number'].to_s.strip
    neighborhood = property_info['neighborhood'].to_s.strip
    municipality = property_info['municipality'].to_s.strip
    state = acquisition_details['state'].to_s.strip

    return unless street.present? && exterior.present? && municipality.present?

    Rails.logger.info "🔍 BUSCANDO PROPIEDAD: #{street} #{exterior}, #{interior}, #{municipality}"

    existing_property = Property.where(
      street: street,
      exterior_number: exterior,
      interior_number: interior,
      neighborhood: neighborhood,
      municipality: municipality
    ).first

    if existing_property.present?
      self.property_id = existing_property.id
      Rails.logger.info "✅ PROPERTY LINKED (EXISTENTE): #{existing_property.id} - #{existing_property.address}"
      return
    end

    begin
      Rails.logger.info "➕ CREANDO NUEVA PROPIEDAD..."

      property_type_name = determine_property_type
      property_type_obj = PropertyType.find_by(name: property_type_name) || PropertyType.first

      unless property_type_obj
        Rails.logger.warn "⚠️ No hay PropertyType en BD. Creando 'otros'..."
        property_type_obj = PropertyType.create!(name: 'otros', description: 'Otros tipos')
      end

      default_price = 1.0
      default_area = 1.0
      default_land_use = acquisition_details['land_use'].to_s.presence || 'HAB'

      new_property = Property.create!(
        user_id: agent&.user_id,
        property_type: property_type_obj,
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
        title: "Propiedad en #{street} #{exterior}",
        description: "Propiedad capturada desde Formulario de Contacto Inicial #{self.opportunity_identifier}",
        land_use: LandUseType.find_by(code: default_land_use)&.property_category || 'habitacional',
        contact_email: general_conditions['owner_email'].to_s,
        contact_phone: general_conditions['owner_phone'].to_s
      )

      self.property_id = new_property.id
      Rails.logger.info "✅ PROPERTY CREATED (NUEVA): #{new_property.id} - #{new_property.address}"

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "❌ ERROR VALIDACIÓN PROPIEDAD: #{e.message}"
      Rails.logger.error e.record.errors.full_messages.inspect
    rescue StandardError => e
      Rails.logger.error "⚠️ ERROR CREANDO PROPIEDAD: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
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

    create_co_owners!(bt, client)
    create_required_documents!(bt, scenario) if scenario
    Rails.logger.info "✅ BT creada (ID: #{bt.id})"
    bt
  end

  def create_co_owners!(business_transaction, primary_client)
    is_heritage = business_transaction.property_acquisition_method&.code == 'herencia'

    count = if is_heritage
              (acquisition_details['heirs_count'] || 1).to_i
            else
              (acquisition_details['co_owners_count'] || 1).to_i
            end

    owner_type = is_heritage ? 'heredero' : 'copropietario'

    percentage_each = (100.0 / count).round(2)
    is_mancomunado = !is_heritage && (general_conditions['marriage_regime_id'].to_i == 4)
    owner_percentage = is_mancomunado ? (percentage_each / 2).round(2) : percentage_each

    # Copropietario principal (quien actúa ante la inmobiliaria)
    business_transaction.business_transaction_co_owners.create!(
      client: primary_client,
      person_name: general_conditions['owner_or_representative_name'],
      percentage: owner_percentage,
      role: 'propietario',
      active: true
    )

    # Cónyuge del principal (solo si NO es herencia + mancomunado)
    if is_mancomunado
      business_transaction.business_transaction_co_owners.create!(
        client: primary_client,
        person_name: "Cónyuge de #{general_conditions['owner_or_representative_name']}",
        percentage: owner_percentage,
        role: 'copropietario',
        active: true
      )
    end

    # Resto de copropietarios/herederos
    (count - 1).times do |i|
      business_transaction.business_transaction_co_owners.create!(
        person_name: "#{owner_type.capitalize} #{i + 2} - Por definir",
        percentage: percentage_each,
        role: owner_type,
        active: true
      )
    end
  end

  def create_required_documents!(business_transaction, scenario)
    return unless scenario.present?

    # Delegar a BusinessTransaction que usa create_required_documents_v2!
    business_transaction.create_required_documents_v2!(scenario)
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
      business_transaction.business_transaction_co_owners.where(role: 'propietario')
    when 'copropietario'
      business_transaction.business_transaction_co_owners
                          .where(role: ['propietario', 'copropietario'])
    when 'ambos'
      business_transaction.business_transaction_co_owners
    when 'adquiriente'
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
