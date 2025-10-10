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

  has_many :agent_transfers, dependent: :destroy
  has_many :co_owners, class_name: 'BusinessTransactionCoOwner', dependent: :destroy

  has_many   :offers, dependent: :destroy

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

  # Callback para iniciar la cola al crear la primera oferta
  after_create_commit -> { process_offer_queue! }, if: -> { offers.exists? }
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

  private

  def must_have_co_owners
    if co_owners.active.empty?
      errors.add(:co_owners, "Debe tener al menos un propietario/copropietario")
    end
  end

  def ownership_percentages_sum_to_100
    return if co_owners.active.empty?
    
    # ✅ USAR .active.sum para consistencia
    total = co_owners.active.sum(&:percentage)
    unless total.round(2) == 100.0
      errors.add(:co_owners, "Los porcentajes deben sumar exactamente 100% (actual: #{total}%)")
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
