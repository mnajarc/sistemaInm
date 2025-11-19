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
  
  # ============================================================
  # SCOPES
  # ============================================================
  scope :pending_conversion, -> { where(status: :completed, business_transaction_id: nil) }
  scope :by_agent, ->(agent_id) { where(agent_id: agent_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  
  attr_accessor :auto_generated_identifier
  
  before_save :generate_folio_if_missing
  before_save :generate_property_identifier_if_blank # ← NUEVO
  
  
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
  
  
  # Convertir a BusinessTransaction
  def convert_to_transaction!
    return false if converted? || business_transaction.present?
    return false unless valid_for_conversion?
    
    ActiveRecord::Base.transaction do
      # 1. Crear o actualizar cliente
      client = find_or_create_client!
      
      # 2. Crear o actualizar propiedad
      property = find_or_create_property!(client)
      
      # 3. Crear BusinessTransaction
      transaction = create_business_transaction!(client, property)
      
      # 4. Crear copropietarios si aplica
      create_co_owners!(transaction)
      
      # 5. Actualizar estado
      update!(
        status: :converted,
        converted_at: Time.current,
        client: client,
        property: property,
        business_transaction: transaction
      )
      
      transaction
    end
  rescue StandardError => e
    Rails.logger.error "Error converting form to transaction: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    errors.add(:base, "Error al convertir: #{e.message}")
    false
  end
  
  # Verificar si está listo para conversión
  def valid_for_conversion?
    completed? && general_conditions.present? && property_info.present?
  end
  
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
  
def general_conditions_complete
  if general_conditions['owner_or_representative_name'].blank?
    errors.add(:general_conditions, "falta el nombre del propietario/representante")
  end
  
  # NUEVAS VALIDACIONES
  if acquisition_details['state'].blank?
    errors.add(:acquisition_details, "debe especificar la entidad federativa")
  end
  
  if acquisition_details['land_use'].blank?
    errors.add(:acquisition_details, "debe especificar el uso de suelo")
  end
end

  # ============================================================
  # MÉTODOS PRIVADOS
  # ============================================================
  
  private

    
  # ============================================================
  # GENERACIÓN AUTOMÁTICA DE IDENTIFICADOR
  # ============================================================
  
  def generate_property_identifier_if_blank
    return if property_human_identifier.present?
    return unless new_record?
    
    self.auto_generated_identifier = true
    
    # USAR display_name en lugar de name (CRÍTICO)
    operation = operation_type&.display_name || "Operación"
    owner = general_conditions['owner_or_representative_name']&.strip
    
    if owner.present?
      self.property_human_identifier = "#{operation} - #{owner}"
    else
      timestamp = Time.current.strftime('%d/%m/%Y %H:%M')
      self.property_human_identifier = "#{operation} - Sin nombre (#{timestamp})"
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
    required_fields = ['property_acquisition_method', 'contract_signer_type', 'owner_or_representative_name']
    
    required_fields.each do |field|
      if general_conditions[field].blank?
        errors.add(:general_conditions, "falta el campo: #{field}")
      end
    end
  end
  
  def general_conditions_complete
    # Validar nombre de la oportunidad
    # if property_human_identifier.blank?
      # errors.add(:property_human_identifier, "debe especificarse el nombre de la oportunidad")
    # end
    
    if general_conditions['owner_or_representative_name'].blank?
      errors.add(:general_conditions, "falta el nombre del propietario/representante")
    end
    
    # if property_acquisition_method_id.blank?
      # errors.add(:base, "debe seleccionar un método de adquisición")
    # end
    
    # if contract_signer_type_id.blank?
      # errors.add(:base, "debe seleccionar quién firmará el contrato")
    # end
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
  def find_or_create_property!(client)
    return property if property.present?
    
    # Parsear dirección completa para extraer componentes
    address_full = property_info['address'] || 'Calle Por Definir 123, CDMX'
    
    # Crear propiedad con TODOS los campos obligatorios
    Property.create!(
      # Relaciones
      user: agent,
      property_type: determine_property_type,
      
      # Dirección completa (legacy)
      address: address_full,
      
      # Dirección desagregada (nuevos campos obligatorios)
      street: 'Calle Por Definir',           # Campo obligatorio
      exterior_number: '123',                 # Campo obligatorio
      interior_number: nil,
      neighborhood: 'Colonia Centro',         # Campo obligatorio
      city: 'Ciudad de México',
      municipality: 'Benito Juárez',          # Campo obligatorio
      state: 'CDMX',
      postal_code: '01000',
      country: 'México',                      # Campo obligatorio
      
      # Precio
      price: property_info['asking_price'] || property_info['estimated_price'] || 0,
      
      # Características físicas
      bedrooms: property_info['bedrooms'] || 0,
      bathrooms: property_info['bathrooms'] || 0,
      built_area_m2: property_info['built_area_m2']&.to_f || 50.0,
      lot_area_m2: property_info['lot_area_m2']&.to_f || 50.0,
      parking_spaces: 0,
      year_built: property_info['acquisition_date']&.to_date&.year || Time.current.year,
      
      # Amenidades (todas false por defecto)
      furnished: false,
      pets_allowed: false,
      elevator: false,
      balcony: false,
      terrace: false,
      garden: false,
      pool: false,
      security: false,
      gym: false,
      
      # Textos descriptivos
      title: generate_property_title,
      description: generate_property_description,
      
      # Información de contacto
      contact_phone: general_conditions['owner_phone'],
      contact_email: general_conditions['owner_email'],
      
      # Uso del suelo
      has_extensions: property_info['has_improvements'] || false,
      land_use: property_info['property_use'] || 'habitacional',
      
      # Notas internas
      internal_notes: "Creado desde formulario de contacto inicial ##{id}\n#{agent_notes}",
      
      # Fechas
      available_from: Date.current,
      published_at: nil  # No publicar automáticamente
    )
  rescue ActiveRecord::RecordInvalid => e
    # Log detallado para debugging
    Rails.logger.error "❌ Error creando Property desde InitialContactForm:"
    Rails.logger.error "   Mensaje: #{e.message}"
    Rails.logger.error "   Formulario ID: #{id}"
    Rails.logger.error "   property_info: #{property_info.inspect}"
    raise
  end
  
  # Generar título de propiedad automáticamente
  def generate_property_title
    type = general_conditions['domicile_type']&.humanize || 'Inmueble'
    price = property_info['asking_price']&.to_f || 0
    
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
      listing_agent: agent,
      current_agent: agent,
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
