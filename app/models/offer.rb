class Offer < ApplicationRecord
  belongs_to :business_transaction
  belongs_to :offerer, class_name: 'Client'
  belongs_to :offer_status

  # Validación: un solo registro activo (pendiente o en evaluación) por oferente y transacción
  validates :offerer_id,
            uniqueness: {
              scope: :business_transaction_id,
              conditions: -> {
                joins(:offer_status)
                  .where(offer_statuses: { name: ['pending'] })
              },
              message: "ya tiene una oferta activa/pendiente para esta transacción"
            }

  # Validaciones de campos
  validates :amount,
            presence: true,
            numericality: { greater_than: 0 }

  # Callback para asignar fecha automáticamente si no se proporciona
  before_validation :set_default_offer_date, on: :create

  # validates :offer_date, presence: true

  # Scopes para filtrar y ordenar ofertas

  scope :in_evaluation_status, -> {
    joins(:offer_status)
        .where(offer_statuses: { name: 'in_evaluation' })
  }
  scope :by_date,        -> { order(:offer_date) }
  scope :active,         -> {
    joins(:offer_status)
      .where.not(offer_statuses: { name: %w[accepted rejected withdrawn] })
  }
  scope :in_queue_order, -> { order(:queue_position) }
 
private

  def set_default_offer_date
    self.offer_date ||= Time.current
  end

end
