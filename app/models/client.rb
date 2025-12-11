class Client < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :marriage_regime, optional: true

  has_many :offered_transactions, class_name: 'BusinessTransaction', foreign_key: 'offering_client_id'
  has_many :acquired_transactions, class_name: 'BusinessTransaction', foreign_key: 'acquiring_client_id'
  has_many :contracts
  has_many :transaction_co_owners, class_name: 'BusinessTransactionCoOwner'
  has_many :initial_contact_forms
  has_many :business_transactions_as_offering_client, 
           class_name: "BusinessTransaction", 
           foreign_key: "offering_client_id",
           dependent: :nullify
  has_many :business_transactions_as_acquiring_client,
           class_name: "BusinessTransaction",
           foreign_key: "acquiring_client_id",
           dependent: :nullify


  has_many :business_transactions


  attr_accessor :first_names, :first_surname, :second_surname
 
  # ✅ NUEVAS RELACIONES PARA OFERTAS
  has_many :offers_made, class_name: 'Offer', foreign_key: 'offerer_id'
  has_many :active_offers, -> { active }, class_name: 'Offer', foreign_key: 'offerer_id'
  has_many :pending_offers, -> { joins(:offer_status).where(offer_statuses: { name: 'pending' }) }, 
           class_name: 'Offer', foreign_key: 'offerer_id'
  has_many :co_ownership_links, 
          class_name: 'CoOwnershipLink',
          foreign_key: :primary_client_id,
          dependent: :destroy
  has_many :co_owners, 
          through: :co_ownership_links,
          source: :co_owner_client



  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :active, inclusion: { in: [true, false] }
  validates :first_names, presence: true
  validates :first_surname, presence: true
  validates :civil_status, presence: true
  validates :email, presence: true, uniqueness: true




  before_save :compose_full_name, :sync_full_name, :clean_names

  scope :active, -> { where(active: true) }
  scope :with_system_user, -> { where.not(user_id: nil) }
  scope :external_only, -> { where(user_id: nil) }
  scope :with_contact, -> { where.not(email: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # ═══════════════════════════════════════════════════════════
  # MÉTODOS
  # ═══════════════════════════════════════════════════════════
  
  # Generar identificador de cliente único
  def generate_client_identifier
    return unless full_name.present?
    
    # Formato: Primer apellido + primeras 2 letras nombre + ID
    name_parts = full_name.strip.split(/\s+/)
    last_name = name_parts.length >= 2 ? name_parts[1] : name_parts[0]
    first_name = name_parts[0]
    
    last_name_clean = I18n.transliterate(last_name.to_s)
      .gsub(/[^a-zA-Z0-9]/, '')
      .upcase
      .slice(0, 10)
    
    first_name_clean = I18n.transliterate(first_name.to_s)
      .gsub(/[^a-zA-Z0-9]/, '')
      .upcase
      .slice(0, 2)
    
    "#{last_name_clean}-#{first_name_clean}-#{id.to_s.rjust(6, '0')}"
  end



  def self.from_initial_contact_form(form)
    attrs = {
      email: form.general_conditions&.dig('owner_email'),
      full_name: form.general_conditions&.dig('owner_or_representative_name'),
      first_names: form.general_conditions&.dig('first_names')&.strip,
      first_surname: form.general_conditions&.dig('first_surname')&.strip,
      second_surname: form.general_conditions&.dig('second_surname')&.strip,
      phone: form.general_conditions&.dig('owner_phone'),
      civil_status: form.general_conditions&.dig('civil_status'),
      marriage_regime_id: form.general_conditions&.dig('marriage_regime_id'),
      notes: form.general_conditions&.dig('notes')
    }

    # Buscar existente por email
    client = find_by(email: attrs[:email]) || new

    # Actualizar atributos
    client.assign_attributes(attrs.compact)
    client
  end


  
  # Crear cliente desde InitialContactForm

  # ========================================
  # MÉTODOS DE INSTANCIA
  # ========================================

  # Actualizar desde InitialContactForm
  def update_from_initial_contact_form(form)
    update(
      email: form.general_conditions&.dig('owner_email'),
      full_name: form.general_conditions&.dig('owner_or_representative_name'),
      first_names: form.general_conditions&.dig('first_names')&.strip,
      first_surname: form.general_conditions&.dig('first_surname')&.strip,
      second_surname: form.general_conditions&.dig('second_surname')&.strip,
      phone: form.general_conditions&.dig('owner_phone'),
      civil_status: form.general_conditions&.dig('civil_status'),
      marriage_regime_id: form.general_conditions&.dig('marriage_regime_id'),
      notes: form.general_conditions&.dig('notes')
    )
  end


  # Nombre completo para mostrar
  def display_name
    full_name.presence || "#{first_names} #{first_surname}".strip
  end








  
  # Validar completitud de datos
  def complete?
    full_name.present? && email.present? && (phone.present? || city.present?)
  end

  def all_transactions
    BusinessTransaction.where(
      'offering_client_id = ? OR acquiring_client_id = ?', id, id
    )
  end

  def has_system_access?
    user_id.present?
  end

  def full_contact_info
    [full_name, email, phone].compact.join(' - ')
  end

  def display_name
    full_name.presence || email.presence || "Cliente ##{id}"
  end

  # ✅ NUEVOS MÉTODOS PARA OFERTAS
  def offers_summary
    {
      total: offers_made.count,
      active: active_offers.count,
      pending: pending_offers.count,
      in_evaluation: offers_made.in_evaluation_status.count
    }
  end

  def has_active_offers?
    active_offers.exists?
  end

  def can_make_offer_on?(business_transaction)
    # No puede ofertar si ya tiene una oferta activa en esa transacción
    !offers_made.active.where(business_transaction: business_transaction).exists?
  end

  private
  
  def compose_full_name
    parts = [
      first_names&.strip,
      first_surname&.strip,
      second_surname&.strip
    ].compact
    
    self.full_name = parts.join(' ')
  end


  # ========================================
  # Sincronizar full_name a partir de componentes
  # ========================================
  def sync_full_name
    return if first_names.blank? || first_surname.blank?

    parts = [first_names.to_s.strip, first_surname.to_s.strip]
    parts << second_surname.to_s.strip if second_surname.present?
    
    self.full_name = parts.join(' ')
  end

  # ========================================
  # Limpiar espacios en blanco
  # ========================================
  def clean_names
    self.first_names = first_names&.strip
    self.first_surname = first_surname&.strip
    self.second_surname = second_surname&.strip
    self.email = email&.strip&.downcase
  end

end
