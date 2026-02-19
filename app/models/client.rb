class Client < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :marriage_regime, optional: true
  belongs_to :nationality_country,
             class_name: "Country",
             optional: true

  belongs_to :birth_country,
             class_name: "Country",
             optional: true



  has_many :offered_transactions, class_name: 'BusinessTransaction', foreign_key: 'offering_client_id'
  has_many :acquired_transactions, class_name: 'BusinessTransaction', foreign_key: 'acquiring_client_id'
  has_many :contracts
  has_many :transaction_co_owners, class_name: 'BusinessTransactionCoOwner', dependent: :nullify
  has_many :initial_contact_forms
  # has_many :business_transactions_as_offering_client, 
           # class_name: "BusinessTransaction", 
           # foreign_key: "offering_client_id",
           # dependent: :nullify
  # has_many :business_transactions_as_acquiring_client,
           # class_name: "BusinessTransaction",
           # foreign_key: "acquiring_client_id",
           # dependent: :nullify
  # has_many :business_transactions
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
  has_many :client_addresses, dependent: :destroy
  has_many :addresses, through: :client_addresses

  accepts_nested_attributes_for :client_addresses,
    allow_destroy: true

  # ============================================================
  # VALIDACIONES
  # ============================================================

  validates :full_name, presence: true
  validates :email,
    presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false },
    allow_blank: false

  validates :phone,
    allow_blank: true,
    format: { with: /\A\+?[0-9\s\-()]{7,20}\z/, message: "formato inválido" }

  validates :active, inclusion: { in: [true, false] }
  validates :first_names, presence: true
  validates :first_surname, presence: true
  validates :civil_status, presence: true
  validates :rfc,
            allow_blank: true,
            format: {
              with: /\A[ A-Z0-9&Ñ]{12,13}\z/,
              message: "no parece un RFC válido"
            }


  # ============================================================
  # CALLBACKS - ORDEN IMPORTANTE
  # ============================================================
  before_validation :clean_names
  before_validation :compose_full_name
  # Para no eliminar clientes que participen en transacciones activas
  before_destroy :prevent_destroy_with_active_participations
  before_save :normalize_rfc


  # ============================================================
  # SCOPES
  # ============================================================
  
  # Búsqueda por nombre completo o email (case-insensitive)
  scope :search_by_full_name_or_email, ->(query) {
    return none if query.blank?
    
    sanitized = "%#{sanitize_sql_like(query.to_s.strip)}%"
    
    where(
      "CONCAT(first_names, ' ', first_surname, ' ', COALESCE(second_surname, '')) ILIKE :q OR email ILIKE :q",
      q: sanitized
    )
  }

  scope :active, -> { where(active: true) }
  scope :with_system_user, -> { where.not(user_id: nil) }
  scope :external_only, -> { where(user_id: nil) }
  scope :with_contact, -> { where.not(email: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # ============================================================
  # MÉTODOS PÚBLICOS
  # ============================================================
   def normalize_rfc
    self.rfc = rfc.to_s.strip.upcase.presence
  end
 
  def display_name
    full_name.presence || "#{first_names} #{first_surname}".strip
  end

  def generate_client_identifier
    return unless full_name.present?
    
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

  def complete?
    full_name.present? && email.present? && (phone.present? || address.present?)
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
    !offers_made.active.where(business_transaction: business_transaction).exists?
  end

  # ============================================================
  # HELPERS DE NACIONALIDAD
  # ============================================================
  def nationality_name
    nationality_country&.nationality || nationality_country&.name
  end

  def nationality_code
    nationality_country&.alpha2_code
  end

  def mexican?
    nationality_code == "MX"
  end

  def foreign?
    nationality_country.present? && !mexican?
  end

  # ============================================================
  # HELPERS DE DIRECCIÓN
  # ============================================================
  def fiscal_address
    client_addresses.includes(:address).find_by(address_type: "fiscal")&.address
  end

  def home_address
    client_addresses.includes(:address).find_by(address_type: "particular")&.address
  end



  # ============================================================
  # MÉTODOS PRIVADOS
  # ============================================================
  private

  def prevent_destroy_with_active_participations
    active_co_ownerships = BusinessTransactionCoOwner
      .where(client_id: id, active: true)
      .joins(:business_transaction)
      .merge(BusinessTransaction.active)

    if active_co_ownerships.exists?
      errors.add(:base, "No se puede eliminar: el cliente participa como copropietario en #{active_co_ownerships.count} transacción(es) activa(s)")
      throw :abort
    end
  end


  # 🔧 ÚNICO callback que arma full_name
  def compose_full_name
    first_n  = first_names.to_s.strip
    first_s  = first_surname.to_s.strip
    second_s = second_surname.to_s.strip

    # Armar nombre con las partes disponibles
    # Si faltan first_n o first_s, esto quedará vacío
    # y la validación presence: true lo va a reventar
    self.full_name = [first_n, first_s, second_s.presence]
                      .compact
                      .reject(&:blank?)
                      .join(' ')
  end

  def clean_names
    self.first_names    = first_names.to_s.strip
    self.first_surname  = first_surname.to_s.strip
    self.second_surname = second_surname.to_s.strip
    self.email          = email.to_s.strip.downcase
    self.phone          = phone.to_s.strip
  end
end
