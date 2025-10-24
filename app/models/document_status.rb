class DocumentStatus < ApplicationRecord
  has_many :document_submissions
  
  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :color, presence: true
  validates :icon, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_position, -> { order(:position) }
  
  # Métodos de conveniencia para estados comunes
  def self.pendiente_solicitud
    find_by(name: 'pendiente_solicitud')
  end
  
  def self.solicitado_cliente
    find_by(name: 'solicitado_cliente')
  end
  
  def self.recibido_revision
    find_by(name: 'recibido_revision')
  end
  
  def self.validado_vigente
    find_by(name: 'validado_vigente')
  end
  
  def self.rechazado
    find_by(name: 'rechazado')
  end
  
  def self.vencido
    find_by(name: 'vencido')
  end
end
