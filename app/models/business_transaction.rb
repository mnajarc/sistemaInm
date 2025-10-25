class BusinessTransaction < ApplicationRecord
  # Relaciones existentes...
  belongs_to :listing_agent, class_name: "User"
  belongs_to :current_agent, class_name: "User"
  belongs_to :selling_agent, class_name: "User", optional: true
  belongs_to :offering_client, class_name: "Client"
  belongs_to :acquiring_client, class_name: "Client", optional: true
  belongs_to :property
  belongs_to :operation_type
  belongs_to :business_status
  belongs_to :transaction_scenario, optional: true
 
  has_many :document_submissions, dependent: :destroy
  has_many :agent_transfers, dependent: :destroy
  has_many :co_owners, class_name: 'BusinessTransactionCoOwner', dependent: :destroy

  has_many   :offers, dependent: :destroy
  has_many :business_transaction_co_owners, inverse_of: :business_transaction, dependent: :destroy
  accepts_nested_attributes_for :business_transaction_co_owners, 
                                allow_destroy: true,
                                reject_if: proc { |attributes| attributes['client_id'].blank? }
  # ✅ NESTED ATTRIBUTES para crear propiedad
  accepts_nested_attributes_for :property, allow_destroy: false, reject_if: :all_blank
  accepts_nested_attributes_for :co_owners, allow_destroy: true, reject_if: :all_blank

  # Validaciones básicas
  validates :start_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  # ✅ VALIDACIONES DE COPROPIEDAD (UNIFICADAS)
  validate :must_have_co_owners
  validate :ownership_percentages_sum_to_100
  validate :no_duplicate_operation_type, on: [ :create, :update ]
  validate :no_conflict_when_acquiring_client_exists, on: [ :create, :update ]

  validates :external_operation_number, uniqueness: true, allow_blank: true
  validates :commission_amount, :commission_vat, numericality: true, allow_nil: true
  validates :deed_number, uniqueness: true, allow_blank: true

  # ✅ SOLO ESTAS DOS VALIDACIONES - LÓGICA CORRECTA
  # validate :ownership_percentages_valid
  # validate :ownership_sums_100
  # Scopes
  scope :active, -> { joins(:business_status).where(business_statuses: { name: [ "available", "reserved" ] }) }
  scope :completed, -> { joins(:business_status).where(business_statuses: { name: [ "sold", "rented" ] }) }
  scope :in_progress, -> { joins(:business_status).where(business_statuses: { name: [ "reserved" ] }) }
  scope :for_operation, ->(operation_type) { where(operation_type: operation_type) }
  scope :for_property, ->(property) { where(property: property) }
  scope :by_current_agent, ->(agent) { where(current_agent: agent) }
  scope :needs_attention, -> { where("estimated_completion_date < ?", Date.current) }

  scope :current, -> { where('contract_expiration_date >= ?', Date.current) }
  scope :expired, -> { where('contract_expiration_date < ?', Date.current) }
  scope :by_legal_act, ->(act) { where(acquisition_legal_act: act) }
  scope :by_municipality, ->(mun) { joins(:property).where('properties.municipality = ?', mun) }


  # Callback para iniciar la cola al crear la primera oferta
  after_create_commit -> { process_offer_queue! }, if: -> { offers.exists? }
  after_update :setup_required_documents, if: :saved_change_to_transaction_scenario_id?

  def required_documents_for_oferente
    return [] unless transaction_scenario
    transaction_scenario.scenario_documents.for_oferente.required
  end
  
  def required_documents_for_adquiriente
    return [] unless transaction_scenario
    transaction_scenario.scenario_documents.for_adquiriente.required
  end
  
  def document_completeness_percentage
    total = document_submissions.count
    return 0 if total.zero?
    
    completed = document_submissions.completed.count
    (completed.to_f / total * 100).round(1)
  end
  
  def setup_required_documents
    return unless transaction_scenario
    DocumentSetupService.new(self).setup_required_documents
  end

  def current_offer
    offers.joins(:offer_status).find_by(offer_statuses: { name: 'in_evaluation' })
  end

  # Business Logic
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

  def total_ownership
    co_owners.active.sum(:percentage)
  end

  def total_ownership_percentage
    co_owners.active.sum(:percentage)
  end

  def has_co_ownership?
    co_owners.active.any?
  end

  def co_owners_summary
    co_owners.active.map(&:display_info).join(', ')
  end

  def is_single_owner?
    co_owners.active.count == 1
  end

  def is_multiple_ownership?
    co_owners.active.count > 1
  end

  def ownership_summary
    if is_single_owner?
      "Propietario único: #{co_owners.first.display_name}"
    else
      "Copropiedad: #{co_owners.active.map(&:display_info).join(', ')}"
    end
  end

# ✅ MÉTODO DE AUTOMATIZACIÓN DE COPROPIETARIOS
def auto_coproperty_setup!(owners:)
  # Limpiar copropietarios existentes
  co_owners.destroy_all if co_owners.exists?
  
  owners.each do |owner_data|
    co_owners.create!(
      client: owner_data[:client],
      person_name: owner_data[:client]&.name || owner_data[:name],
      percentage: owner_data[:percentage],
      role: owner_data[:role] || 'propietario'
    )
  end
end


  def current_contract?
    contract_expiration_date && contract_expiration_date >= Date.current
  end

  def commercial_description
    "#{celebration_place}, #{contract_expiration_date}, amount: #{commission_amount}"
  end


  # Recibe una nueva oferta: la crea como pending y procesa la cola
  def receive_offer(client, amount, terms: nil, notes: nil, valid_until: nil, offer_date: nil)
    offer = offers.create!(
      offerer: client,
      amount: amount,
      terms: terms,
      notes: notes,
      valid_until: valid_until,
      offer_date: offer_date, # Puede ser nil, se asignará automáticamente
      offer_status: OfferStatus.find_by(name: 'pending')
      )
    process_offer_queue!
    offer
  end

  # Procesa la cola: promueve la siguiente oferta pending a in_evaluation
  def process_offer_queue!
    return if offers.joins(:offer_status)
                    .where(offer_statuses: { name: 'in_evaluation' })
                    .exists?

    next_offer = offers.joins(:offer_status)
                       .where(offer_statuses: { name: 'pending' })
                       .order(:offer_date)
                       .first
    return unless next_offer

    next_offer.update!(offer_status: OfferStatus.find_by(name: 'in_evaluation'))
  end

  # Acepta la oferta: marca accepted, asigna acquiring_client y cierra transacción
  def accept_offer!(offer)
    transaction do
      offer.update!(offer_status: OfferStatus.find_by(name: 'accepted'))
      update!(acquiring_client: offer.offerer,
              business_status: BusinessStatus.find_by(name: 'reserved'))
      # Rechaza todas las demás ofertas activas
      offers.joins(:offer_status)
            .where.not(id: offer.id)
            .where(offer_statuses: { name: %w[pending in_evaluation] })
            .update_all(offer_status_id: OfferStatus.find_by(name: 'rejected').id)
    end
  end

  # Rechaza oferta y avanza la cola
  def reject_offer!(offer)
    transaction do
      offer.update!(offer_status: OfferStatus.find_by(name: 'rejected'))
      process_offer_queue!
    end
  end

  # ✅ MÉTODOS DE CONVENIENCIA
  def has_multiple_co_owners?
    co_owners.active.count > 1
  end

  def co_ownership_summary
    if co_owners.active.count > 1
      "#{co_owners.active.count} copropietarios: #{co_owners.active.map(&:display_name).join(', ')}"
    else
      "Propietario único: #{co_owners.active.first&.display_name}"
    end
  end


  def total_documented_percentage
    co_owners.active.sum(:percentage) || 0
  end

  def pending_co_owner_documents
    co_owners.active.map(&:documents_checklist).flatten.select { |doc| doc[:required] && !doc[:uploaded] }
  end

  # ✅ AUDITORÍA USANDO agent_transfers EXISTENTE
  def log_agent_transfer(from_agent, to_agent, reason)
    AgentTransfer.create!(
      business_transaction: self,
      from_agent: from_agent,
      to_agent: to_agent,
      transferred_by: Current.user,
      reason: reason,
      transferred_at: Time.current
    )
  end

  def audit_trail
    audits = []
    
    # Creación
    audits << {
      event: 'created',
      description: "Transacción creada",
      user: user&.full_name || 'Sistema',
      timestamp: created_at,
      icon: 'plus-circle'
    }
    
    # Cambios de agente
    agent_transfers.each do |transfer|
      audits << {
        event: 'agent_changed',
        description: "Agente: #{transfer.from_agent&.full_name} → #{transfer.to_agent&.full_name}",
        reason: transfer.reason,
        user: transfer.transferred_by&.full_name,
        timestamp: transfer.transferred_at,
        icon: 'exchange-alt'
      }
    end
    
    # Documentos
    document_submissions.order(:created_at).each do |doc|
      audits << {
        event: 'document_uploaded',
        description: "Documento: #{doc.document_type&.display_name}",
        user: doc.uploaded_by&.full_name || 'Sistema',
        timestamp: doc.created_at,
        icon: 'file-upload'
      }
      
      if doc.validated_at.present?
        audits << {
          event: 'document_validated',
          description: "Documento validado: #{doc.document_type&.display_name}",
          user: doc.validated_by&.full_name,
          timestamp: doc.validated_at,
          icon: 'check-circle'
        }
      end
    end
    
    audits.sort_by { |a| a[:timestamp] }.reverse
  end

  private


  def must_have_co_owners
    # Para transacciones nuevas: revisar nested attributes
    if new_record?
      incoming = []
      
      # Revisar business_transaction_co_owners_attributes
      if respond_to?(:business_transaction_co_owners_attributes) && business_transaction_co_owners_attributes.present?
        incoming += business_transaction_co_owners_attributes.reject do |attrs|
          attrs['_destroy'] == '1' || attrs[:_destroy] == true || 
          attrs['active'] == false || attrs[:active] == false
        end
      end
      
      # Revisar co_owners_attributes (alias)
      if respond_to?(:co_owners_attributes) && co_owners_attributes.present?
        incoming += co_owners_attributes.reject do |attrs|
          attrs['_destroy'] == '1' || attrs[:_destroy] == true || 
          attrs['active'] == false || attrs[:active] == false
        end
      end
      
      # También considerar co_owners ya cargados en memoria (build)
      existing_in_memory = co_owners.reject(&:marked_for_destruction?)
      
      total = incoming.count + existing_in_memory.count
      
      if total == 0
        errors.add(:co_owners, "Debe tener al menos un propietario/copropietario")
      end
    else
      # Para transacciones existentes: revisar base de datos
      if co_owners.active.empty?
        errors.add(:co_owners, "Debe tener al menos un propietario/copropietario")
      end
    end
  end

  def ownership_percentages_sum_to_100
    # Solo validar si hay copropietarios
    return if co_owners.empty?
    
    # Para nuevos registros, sumar lo que viene en nested + lo que está en memoria
    if new_record?
      total = 0
      
      co_owners.each do |co_owner|
        next if co_owner.marked_for_destruction?
        total += (co_owner.percentage || 0)
      end
      
      # Si total es 0, significa que aún no se asignaron porcentajes
      return if total == 0
      
      unless total.round(2) == 100.0
        errors.add(:co_owners, "Los porcentajes deben sumar exactamente 100% (actual: #{total.round(2)}%)")
      end
    else
      # Para registros existentes
      total = co_owners.active.sum(&:percentage)
      unless total.round(2) == 100.0
        errors.add(:co_owners, "Los porcentajes deben sumar exactamente 100% (actual: #{total.round(2)}%)")
      end
    end
  end


  def no_duplicate_operation_type
    return unless property && operation_type

    duplicates = BusinessTransaction
                  .for_property(property)
                  .for_operation(operation_type)
                  .active
                  .where.not(id: id)

    if duplicates.exists?
      existing = duplicates.first
      errors.add(:operation_type,
        "Ya existe una transacción activa de #{operation_type.display_name} " \
        "para esta propiedad (Agente: #{existing.current_agent.email})"
      )
    end
  end

  def no_conflict_when_acquiring_client_exists
    return unless property && operation_type
    return if acquiring_client_id.nil?

    opposite_operations = OperationType.where.not(id: operation_type_id)

    conflicts = BusinessTransaction
                  .for_property(property)
                  .where(operation_type: opposite_operations)
                  .where.not(acquiring_client_id: nil)
                  .where.not(id: id)

    if conflicts.exists?
      conflict = conflicts.first
      errors.add(:acquiring_client,
        "No se puede asignar cliente adquiriente porque la operación de " \
        "#{conflict.operation_type.display_name} ya tiene cliente asignado " \
        "(#{conflict.acquiring_client.name})"
      )
    end
  end
end
