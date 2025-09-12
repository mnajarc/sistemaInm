class BusinessTransaction < ApplicationRecord
  # Relaciones existentes...
  belongs_to :listing_agent, class_name: 'User'
  belongs_to :current_agent, class_name: 'User' 
  belongs_to :selling_agent, class_name: 'User', optional: true
  belongs_to :offering_client, class_name: 'Client'
  belongs_to :acquiring_client, class_name: 'Client', optional: true
  belongs_to :property
  belongs_to :operation_type
  belongs_to :business_status
  
  has_many :agent_transfers, dependent: :destroy
  
  # Validaciones básicas
  validates :start_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  
  # ✅ SOLO ESTAS DOS VALIDACIONES - LÓGICA CORRECTA
  validate :no_duplicate_operation_type, on: [:create, :update]
  validate :no_conflict_when_acquiring_client_exists, on: [:create, :update]
  
  # Scopes
  scope :active, -> { joins(:business_status).where(business_statuses: { name: ['available', 'reserved'] }) }
  scope :in_progress, -> { joins(:business_status).where(business_statuses: { name: ['reserved'] }) }
  scope :for_operation, ->(operation_type) { where(operation_type: operation_type) }
  scope :for_property, ->(property) { where(property: property) }
  scope :by_current_agent, ->(agent) { where(current_agent: agent) }
  scope :needs_attention, -> { where('estimated_completion_date < ?', Date.current) }
  scope :completed, -> { joins(:business_status).where(business_statuses: { name: ['sold', 'rented'] }) }
  
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
    business_status.name == 'available'
  end

  private

  # ✅ VALIDACIÓN 1: No duplicar mismo tipo de operación
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

  # ✅ VALIDACIÓN 2: Bloqueo mutuo cuando hay adquiriente
  def no_conflict_when_acquiring_client_exists
    return unless property && operation_type
    return if acquiring_client_id.nil?  # Solo validar si ESTA transacción tiene adquiriente
    
    # Buscar operaciones contrarias (venta vs alquiler) que también tengan adquiriente
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
