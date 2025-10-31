class BusinessTransaction < ApplicationRecord
  belongs_to :listing_agent, class_name: "User"
  belongs_to :current_agent, class_name: "User"
  belongs_to :selling_agent, class_name: "User", optional: true
  belongs_to :offering_client, class_name: "Client"
  belongs_to :acquiring_client, class_name: "Client", optional: true
  belongs_to :property
  belongs_to :operation_type
  belongs_to :business_status
  belongs_to :transaction_scenario, optional: true
  belongs_to :co_ownership_type, optional: true

  after_create :assign_transaction_scenario_by_category
  after_create :setup_required_documents


  has_many :document_submissions, dependent: :destroy
  has_many :agent_transfers, dependent: :destroy
  has_many :business_transaction_co_owners, inverse_of: :business_transaction, dependent: :destroy
  has_many :offers, dependent: :destroy
  alias_method :co_owners, :business_transaction_co_owners
  accepts_nested_attributes_for :business_transaction_co_owners,
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['client_id'].blank? && attributes['person_name'].blank? }
  accepts_nested_attributes_for :property, allow_destroy: false, reject_if: :all_blank

  validates :start_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  # validate :must_have_co_owners
  # validate :ownership_percentages_sum_to_100

  scope :active, -> { joins(:business_status).where(business_statuses: { name: ["available", "reserved"] }) }
  scope :completed, -> { joins(:business_status).where(business_statuses: { name: ["sold", "rented"] }) }
  
  # Método unificado para obtener el agente responsable
  def assigned_agent
    current_agent || selling_agent || listing_agent
  end

  # Helper para email con fallback
  def assigned_agent_email
    assigned_agent&.email || 'sin-agente@sistemainm.local'
  end

  # Helper para nombre completo
  def assigned_agent_name
    assigned_agent&.full_name || assigned_agent&.email || 'Sin agente asignado'
  end
def audit_trail
  []  # Retorna array vacío por ahora
end

def co_ownership_notes
  nil  # O retorna un valor por defecto
end

  def transfer_to_agent!(new_agent, reason, transferred_by)
    transaction do
      agent_transfers.create!(
        from_agent: current_agent,
        to_agent: new_agent,
        transferred_by: transferred_by,
        reason: reason,
        transferred_at: Time.current
      )
      update!(current_agent: new_agent)
    end
  end
  def revenue
    return 0 unless completed?
    (price * (commission_percentage || 0) / 100).round(2)
  end

  def completed?
    %w[sold rented].include?(business_status.name)
  end

  def available?
    business_status.name == "available"
  end

  def total_ownership_percentage
    business_transaction_co_owners.active.sum(:percentage)
  end

  def is_single_owner?
    business_transaction_co_owners.active.count == 1
  end

  private

# ============================================================
# CALLBACK 1: Asignar TransactionScenario automáticamente
# ============================================================
def assign_transaction_scenario_by_category
  return if transaction_scenario.present?  # Si ya tiene scenario, no hacer nada
  
  # Determinar category basado en operation_type.name
  category = determine_scenario_category
  return unless category
  
  # Buscar scenario por categoría
  scenario = TransactionScenario.find_by(category: category, active: true)
  
  if scenario
    update_column(:transaction_scenario_id, scenario.id)
    Rails.logger.info "✅ Scenario asignado automáticamente: #{scenario.name}"
  else
    Rails.logger.warn "⚠️  No se encontró scenario para categoría: #{category}"
  end
rescue StandardError => e
  Rails.logger.error "❌ Error asignando scenario: #{e.message}"
end


# Determinar categoría del scenario basado en operation_type
def determine_scenario_category
  return nil unless operation_type.present?
  
  case operation_type.name
  when 'sale'
    'compraventa'
  when 'rent'
    # Detectar si es habitacional o comercial
    if property&.property_type&.name.to_s.include?('apartment') || 
       property&.property_type&.name.to_s.include?('house')
      'renta_habitacional'
    else
      'renta_comercial'
    end
  else
    nil
  end
end


# ============================================================
# CALLBACK 2: Crear DocumentSubmissions requeridos
# ============================================================
def setup_required_documents
  return unless transaction_scenario.present?
  
  begin
    service = DocumentSetupService.new(self)
    service.setup_required_documents
    Rails.logger.info "✅ Documentos requeridos creados automáticamente"
  rescue StandardError => e
    Rails.logger.error "❌ Error creando documentos: #{e.message}"
  end
end

  def must_have_co_owners
    active_co_owners = if new_record?
                         business_transaction_co_owners.reject(&:marked_for_destruction?)
                       else
                         business_transaction_co_owners.where(active: true)
                       end

    if active_co_owners.empty?
      errors.add(:business_transaction_co_owners, "Debe tener al menos un propietario/copropietario")
    end
  end

  def ownership_percentages_sum_to_100
    return if business_transaction_co_owners.empty?

    active_co_owners = if new_record?
                         business_transaction_co_owners.reject(&:marked_for_destruction?)
                       else
                         business_transaction_co_owners.where(active: true)
                       end

    return if active_co_owners.empty?

    total = active_co_owners.sum(&:percentage)

    unless total.round(2) == 100.0
      errors.add(:business_transaction_co_owners, "Los porcentajes deben sumar exactamente 100% (actual: #{total.round(2)}%)")
    end
  end
end
