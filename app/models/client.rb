class Client < ApplicationRecord
  # Relación con User (para portal cliente)
  belongs_to :user, optional: true
  
  # Relaciones con transacciones
  has_many :offered_transactions, 
           class_name: 'BusinessTransaction', 
           foreign_key: 'offering_client_id'
  has_many :acquired_transactions, 
           class_name: 'BusinessTransaction', 
           foreign_key: 'acquiring_client_id'
  has_many :offered_properties, through: :offered_transactions, source: :property
  has_many :acquired_properties, through: :acquired_transactions, source: :property
  
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :phone, presence: true
  
  scope :active, -> { where(active: true) }
  
  def full_name_with_email
    "#{name} (#{email})"
  end
  
  def all_transactions
    BusinessTransaction.where(
      "offering_client_id = ? OR acquiring_client_id = ?", 
      id, id
    )
  end
   
  # ✅ MÉTODO PARA ENCONTRAR O CREAR DESDE USER
  def self.find_or_create_for_user(user)
    return nil unless user&.client?
    
    # Buscar por relación directa primero
    client = user.client
    return client if client
    
    # Buscar por email como fallback
    client = find_by(email: user.email)
    if client
      client.update(user: user)
      return client
    end
    
    # Crear nuevo client si no existe
    create!(
      user: user,
      name: user.email.split('@').first.humanize,
      email: user.email,
      phone: 'No especificado',
      address: 'No especificado'
    )
  end
end
