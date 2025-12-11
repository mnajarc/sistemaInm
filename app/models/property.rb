# app/models/property.rb
class Property < ApplicationRecord
  # ═══════════════════════════════════════════════════════════════════════════
  # RELACIONES EXISTENTES (TODO LO QUE TENÍAS)
  # ═══════════════════════════════════════════════════════════════════════════
  belongs_to :user
  belongs_to :property_type, optional: true
  belongs_to :co_ownership_type, optional: true
  belongs_to :land_use_type, optional: true

  has_many :exclusivities, class_name: "PropertyExclusivity", dependent: :destroy
  has_many :commissions, dependent: :nullify
  has_many :business_transactions, dependent: :destroy
  has_one :current_business_transaction,
          -> { where(business_statuses: { name: [ "available", "reserved" ] }).joins(:business_status) },
          class_name: "BusinessTransaction"

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVAS RELACIONES - PARA IDENTIFICADORES
  # ═══════════════════════════════════════════════════════════════════════════
  has_many :initial_contact_forms, dependent: :nullify
  has_many :offering_clients, through: :business_transactions
  has_many :acquiring_clients, through: :business_transactions

  # ═══════════════════════════════════════════════════════════════════════════
  # CALLBACKS EXISTENTES
  # ═══════════════════════════════════════════════════════════════════════════

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVO CALLBACK - PARA GENERAR PROPERTY ID
  # ═══════════════════════════════════════════════════════════════════════════
  before_validation :default_interior_number
  before_validation :generate_full_address
  before_validation :generate_property_id_on_create
  before_save :sanitize_input

  # ═══════════════════════════════════════════════════════════════════════════
  # VALIDACIONES EXISTENTES (TODO LO QUE TENÍAS)
  # ═══════════════════════════════════════════════════════════════════════════
  validates :price, :address, :city, :state, :postal_code,
            :built_area_m2, :lot_area_m2, presence: true
  validates :built_area_m2, :lot_area_m2, numericality: { greater_than: 0 }
  validates :price, numericality: {
    greater_than: 0,
    less_than: 1_000_000_000
  }
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 10000 }

  validates :street, :exterior_number, :neighborhood, :municipality, :country,
            presence: true, if: -> { street.present? }

  validates :land_use, inclusion: { in: %w[habitacional comercial mixto industrial otros], allow_blank: true }
  validates :human_readable_identifier, uniqueness: true, allow_blank: true
  validates :property_type_id, presence: true

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVAS VALIDACIONES - PARA PROPERTY ID Y DEDUPLICACIÓN
  # ═══════════════════════════════════════════════════════════════════════════
  # validates :property_id, presence: true, uniqueness: true

  # Validar ubicación única - PREVENIR DUPLICADOS GEOGRÁFICOS
  validates :street, :exterior_number, :neighborhood, :municipality, :state, presence: true
  # ✅ ÚNICA validación de uniqueness - el property_id lo contiene TODO
  validates :property_id, presence: true, uniqueness: { message: "Ya existe una propiedad con esta ubicación exacta" }

  # ═══════════════════════════════════════════════════════════════════════════
  # SCOPES EXISTENTES (TODO LO QUE TENÍAS)
  # ═══════════════════════════════════════════════════════════════════════════
  scope :by_type, ->(type) { joins(:property_type).where(property_types: { name: type }) }
  scope :published, -> { where.not(published_at: nil) }
  scope :with_active_business, -> { joins(:business_transactions).merge(BusinessTransaction.active) }
  
  scope :available_for_sale, -> { joins(business_transactions: :operation_type)
                                    .where(operation_types: { name: "sale" })
                                    .merge(BusinessTransaction.active) }
  scope :available_for_rent, -> { joins(business_transactions: :operation_type)
                                     .where(operation_types: { name: "rent" })
                                     .merge(BusinessTransaction.active) }

  scope :with_extensions, -> { where(has_extensions: true) }
  scope :by_municipality, ->(mun) { where(municipality: mun) }
  scope :by_neighborhood, ->(neigh) { where(neighborhood: neigh) }
  scope :residential, -> { where(land_use: 'habitacional') }

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVO SCOPE - PARA BUSCAR POR PROPERTY ID
  # ═══════════════════════════════════════════════════════════════════════════
  scope :by_property_id, ->(id) { where(property_id: id) }
  scope :by_identifier, ->(id) { where(human_readable_identifier: id) }

  # ═══════════════════════════════════════════════════════════════════════════
  # MÉTODOS PÚBLICOS EXISTENTES (TODO LO QUE TENÍAS)
  # ═══════════════════════════════════════════════════════════════════════════

  def land_use_display
    case land_use
    when 'habitacional' then 'Residencial'
    when 'comercial' then 'Comercial'
    when 'mixto' then 'Mixto'
    when 'industrial' then 'Industrial'
    else land_use&.titleize || 'No especificado'
    end
  end

  def has_active_transaction?
    business_transactions.joins(:business_status)
                        .where(business_statuses: { name: ['available', 'reserved'] })
                        .exists?
  end

  def current_agent
    current_business_transaction&.current_agent
  end

  def current_status
    primary_business_transaction&.business_status&.display_name || "Sin estado"
  end

  def has_multiple_operations?
    business_transactions.count > 1
  end

  def available_operations
    business_transactions.active.joins(:operation_type).pluck("operation_types.display_name")
  end

  def land_use_human
    case land_use
    when 'habitacional' then "Residential"
    when 'comercial' then "Commercial"
    when 'mixto' then "Mixed"
    when 'industrial' then "Industrial"
    else
      land_use.to_s.titleize
    end
  end

  def current_operations
    business_transactions.active.joins(:operation_type).pluck("operation_types.display_name")
  end

  def available_for_sale?
    business_transactions.active.joins(:operation_type).exists?(operation_types: { name: "sale" })
  end

  def available_for_rent?
    business_transactions.active.joins(:operation_type).exists?(operation_types: { name: "rent" })
  end

  def operation_history
    business_transactions.joins(:operation_type, :business_status)
                        .order(:start_date)
                        .pluck("operation_types.display_name",
                               "business_statuses.display_name",
                               :start_date, :price)
  end

  def available_for_operation?(operation_type)
    !has_active_transaction_for?(operation_type)
  end

  def has_active_transaction_for?(operation_type)
    business_transactions
      .joins(:business_status, :operation_type)
      .where(operation_types: { id: operation_type.id })
      .where(business_statuses: { name: [ "available", "reserved" ] })
      .exists?
  end

  def has_reserved_transaction_for?(operation_type)
    business_transactions
      .joins(:business_status, :operation_type)
      .where(operation_types: { id: operation_type.id })
      .where(business_statuses: { name: "reserved" })
      .exists?
  end

  def has_co_ownership?
    co_ownership_type.present?
  end

  def co_ownership_display
    return "Propietario único" unless has_co_ownership?
    
    details = co_owners_details.present? ? " - #{co_owners_details}" : ""
    "#{co_ownership_type.display_name}#{details}"
  end

  def current_agent_for_operation(operation_type)
    transaction = business_transactions
                    .joins(:operation_type)
                    .where(operation_types: { id: operation_type.id })
                    .active
                    .first

    transaction&.current_agent
  end

  def operation_status_summary
    summary = {}

    OperationType.active.each do |op_type|
      if has_reserved_transaction_for?(op_type)
        summary[op_type.name] = {
          status: "reserved",
          agent: current_agent_for_operation(op_type)&.email,
          message: "Oferta en proceso"
        }
      elsif has_active_transaction_for?(op_type)
        summary[op_type.name] = {
          status: "available",
          agent: current_agent_for_operation(op_type)&.email,
          message: "Disponible"
        }
      else
        summary[op_type.name] = {
          status: "none",
          agent: nil,
          message: "Sin transacción activa"
        }
      end
    end

    summary
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVOS MÉTODOS - PARA PROPERTY ID
  # ═══════════════════════════════════════════════════════════════════════════

  # Generar PROPERTY ID en callback al crear
  def generate_property_id_on_create
    return if property_id.present?
    self.interior_number = "0" if interior_number.blank?


    self.property_id = self.class.generate_geographic_id(
      street,
      exterior_number,
      interior_number,
      municipality,
      state,
      property_type&.name
    )
    self.property_id_generated_at = Time.current

    Rails.logger.info "🗺️ Property ID generado: #{property_id}"
  end

  # Método estático: Generar ID geográfico (SOLO ubicación + tipo)
  def self.generate_geographic_id(street, ext_num, interior_num, municipality, state, property_type = nil)
    # 1. Normalizar calle
    street_norm = I18n.transliterate(street.to_s)
      .downcase
      .gsub(/[^a-z0-9]/, '')
      .slice(0, 15)

    # 2. Normalizar número exterior
    ext_norm = ext_num.to_s
      .gsub(/[^a-z0-9]/, '')
      .upcase
      .slice(0, 6)

    # 3. Normalizar número interior
    interior_norm = interior_num.to_s
      .gsub(/[^a-z0-9]/, '')
      .upcase
      .slice(0, 6)

    # 4. Normalizar municipio
    municipality_norm = I18n.transliterate(municipality.to_s)
      .downcase
      .gsub(/[^a-z0-9]/, '')
      .slice(0, 8)

    # 5. Código de estado
    state_obj = MexicanState.find_by(name: state)
    state_code = state_obj&.code || state.to_s.slice(0, 3).upcase

    # 5. Código de tipo de propiedad
    type_code = case property_type&.downcase
                when /casa|vivienda|habitacion|unifamiliar/ then 'C'
                when /departamento|apartamento|piso/ then 'D'
                when /comercial|local|tienda/ then 'L'
                when /bodega|industrial|nave/ then 'B'
                when /terreno|lote/ then 'T'
                when /oficina|consultorio/ then 'O'
                else 'X'
                end

    # 7. Formato final: CALLE-NUMERO-MUNICIPIO-ESTADO-TIPO
    "#{street_norm.upcase}-#{ext_norm}-#{interior_norm}-#{municipality_norm.upcase}-#{state_code}-#{type_code}"
  end

  # Búsqueda por UBICACIÓN EXACTA (para deduplicación)
  def self.find_by_location(street, ext_num, int_num, neighborhood, municipality, state)
    find_by(
      street: street,
      exterior_number: ext_num,
      interior_number: int_num,
      neighborhood: neighborhood,
      municipality: municipality,
      state: state,
      country: 'México'
    )
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # HELPERS EXISTENTES
  # ═══════════════════════════════════════════════════════════════════════════

  def full_address
    "#{street} #{exterior_number}#{interior_number.present? ? " Int. #{interior_number}" : ""}, #{neighborhood}, #{postal_code} #{municipality}, #{state}, #{country}"
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # ✅ NUEVO HELPER
  # ═══════════════════════════════════════════════════════════════════════════

  def address_compact
    "#{street} #{exterior_number}, #{municipality}, #{state}"
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # MÉTODOS PRIVADOS (TODO LO QUE TENÍAS)
  # ═══════════════════════════════════════════════════════════════════════════
  private

  def default_interior_number
    self.interior_number = "0" if interior_number.blank?
  end

  def generate_full_address
    # Generar dirección completa si tiene datos desglosados
    if street.present? || exterior_number.present?
      self.address = [
        "#{street} #{exterior_number}".strip,
        interior_number.presence,
        neighborhood,
        municipality
      ].compact.join(', ')
    end
  end

  def sanitize_input
    self.title = Rails::Html::FullSanitizer.new.sanitize(title) if title.present?
    self.description = Rails::Html::WhiteListSanitizer.new.sanitize(
      description,
      tags: %w[p br strong em],
      attributes: []
    ) if description.present?
  end
end

