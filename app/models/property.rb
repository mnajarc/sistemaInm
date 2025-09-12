class Property < ApplicationRecord
  # Relaciones existentes
  belongs_to :user
  belongs_to :property_type, optional: true


  has_many :exclusivities, class_name: "PropertyExclusivity", dependent: :destroy
  has_many :commissions, dependent: :nullify
  has_many :business_transactions, dependent: :destroy
  has_one :current_business_transaction, 
          -> { where(business_statuses: { name: ['available', 'reserved'] }).joins(:business_status) }, 
          class_name: 'BusinessTransaction'
  

  # NUEVAS RELACIONES - AGREGAR ESTAS LÍNEAS:

  # Relaciones a través de business_transactions
  has_many :offering_clients, through: :business_transactions
  has_many :acquiring_clients, through: :business_transactions
  

  # Validaciones existentes...
  validates :price, :address, :city, :state, :postal_code,
            :built_area_m2, :lot_area_m2, presence: true
  validates :built_area_m2, :lot_area_m2, numericality: { greater_than: 0 }
  validates :price, numericality: { 
    greater_than: 0, 
    less_than: 1_000_000_000 
  }
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 10000 }
  validate :sanitize_input
  
  # NUEVOS SCOPES - AGREGAR ESTOS:
  scope :by_type, ->(type) { joins(:property_type).where(property_types: { name: type }) }
  scope :published, -> { where.not(published_at: nil) }

  scope :with_active_business, -> { joins(:business_transactions).merge(BusinessTransaction.active) }
  scope :available_for_sale, -> { joins(business_transactions: :operation_type)
                                    .where(operation_types: { name: 'sale' })
                                    .merge(BusinessTransaction.active) }
  scope :available_for_rent, -> { joins(business_transactions: :operation_type)
                                     .where(operation_types: { name: 'rent' }) 
                                     .merge(BusinessTransaction.active) }
  
  # Métodos de conveniencia
  def current_status
    primary_business_transaction&.business_status&.display_name || 'Sin estado'
  end
  
  def has_multiple_operations?
    business_transactions.count > 1
  end
  
  def available_operations
    business_transactions.active.joins(:operation_type).pluck('operation_types.display_name')
  end


  def current_operations
    business_transactions.active.joins(:operation_type).pluck('operation_types.display_name')
  end
  
  def available_for_sale?
    business_transactions.active.joins(:operation_type).exists?(operation_types: { name: 'sale' })
  end
  
  def available_for_rent?
    business_transactions.active.joins(:operation_type).exists?(operation_types: { name: 'rent' })
  end
  
  def operation_history
    business_transactions.joins(:operation_type, :business_status)
                        .order(:start_date)
                        .pluck('operation_types.display_name', 
                               'business_statuses.display_name', 
                               :start_date, :price)
  end
  
  # ✅ MÉTODOS DE ESTADO POR OPERACIÓN
  def available_for_operation?(operation_type)
    !has_active_transaction_for?(operation_type)
  end
  
  def has_active_transaction_for?(operation_type)
    business_transactions
      .joins(:business_status, :operation_type)
      .where(operation_types: { id: operation_type.id })
      .where(business_statuses: { name: ['available', 'reserved'] })
      .exists?
  end
  
  def has_reserved_transaction_for?(operation_type)
    business_transactions
      .joins(:business_status, :operation_type)
      .where(operation_types: { id: operation_type.id })
      .where(business_statuses: { name: 'reserved' })
      .exists?
  end
  
  def current_agent_for_operation(operation_type)
    transaction = business_transactions
                    .joins(:operation_type)
                    .where(operation_types: { id: operation_type.id })
                    .active
                    .first
    
    transaction&.current_agent
  end
  
  # Información para mostrar en vistas
  def operation_status_summary
    summary = {}
    
    OperationType.active.each do |op_type|
      if has_reserved_transaction_for?(op_type)
        summary[op_type.name] = {
          status: 'reserved',
          agent: current_agent_for_operation(op_type)&.email,
          message: "Oferta en proceso"
        }
      elsif has_active_transaction_for?(op_type)  
        summary[op_type.name] = {
          status: 'available',
          agent: current_agent_for_operation(op_type)&.email,
          message: "Disponible"
        }
      else
        summary[op_type.name] = {
          status: 'none',
          agent: nil,
          message: "Sin transacción activa"
        }
      end
    end
    
    summary
  end

  private
  
  def sanitize_input
    self.title = Rails::Html::FullSanitizer.new.sanitize(title) if title.present?
    self.description = Rails::Html::WhiteListSanitizer.new.sanitize(
      description, 
      tags: %w[p br strong em],
      attributes: []
    ) if description.present?
  end
end

