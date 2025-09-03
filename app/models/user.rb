class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  
  # anteriormente se tenía en memoria y se cambia por una tabla para dar mayor flexibilidad al modelo
  # enum :role, { client: 0, agent: 1, admin: 2, superadmin: 3 }
  belongs_to :role

  has_many :properties, dependent: :destroy
  
  validates :role, presence: true
  validate :role_change_authorization, if: :role_changed?
  
  after_initialize :set_default_role, if: :new_record?
  before_update :prevent_unauthorized_role_change
  
  # ✅ SCOPE PARA USUARIOS GESTIONABLES
  scope :manageable_by, ->(manager) { 
    where("role < ?", manager.role_before_type_cast)
  }
  
  # ✅ NIVELES DE ROL (para lógica de interfaz)
  def role_level
    role.level
  end
  
  # ✅ VERIFICAR SI PUEDE SER GESTIONADO POR OTRO USUARIO
  def can_be_managed_by?(manager_user)
    return false unless manager_user
    self.role_before_type_cast < manager_user.role_before_type_cast
  end
  
  # ✅ VERIFICAR SI SE PUEDE CAMBIAR A UN ROL ESPECÍFICO
  def can_change_role_to?(new_role, changer_user)
    return false unless changer_user
    
    # Convertir nuevo rol a integer
    new_role_int = case new_role
    when String
      User.roles[new_role]
    when Symbol
      User.roles[new_role.to_s]
    when Integer
      new_role
    else
      nil
    end
    
    return false if new_role_int.nil?
    
    # Asegurar comparación de enteros
    changer_role_int = changer_user.role_before_type_cast.to_i
    current_role_int = self.role_before_type_cast.to_i
    
    # El changer debe tener rol MAYOR (más poder) que el usuario actual Y que el nuevo rol
    changer_role_int > current_role_int && changer_role_int > new_role_int
  end
  
  # ✅ MÉTODOS DE VERIFICACIÓN DE ROL
  def superadmin?
    role.name == 'superadmin'
  end
  
  def admin_or_above?
    %w[superadmin admin].include?(role.name)
  end
  
  def can_manage_user?(other_user)
    role.level < other_user.role.level
  end
  
  # ✅ VERIFICAR SI ESTÁ ACTIVO
  def active?
    respond_to?(:active) ? (active.nil? ? true : active) : true
  end
  
  # ✅ NOMBRE DEL ROL EN ESPAÑOL
  def role_name
    case role
    when 'superadmin'
      'SuperAdministrador'
    when 'admin'
      'Administrador'
    when 'agent'
      'Agente'
    when 'client'
      'Cliente'
    else
      'Sin rol'
    end
  end
  
  # ✅ MÉTODO DE DEBUG PARA TROUBLESHOOTING
  def debug_role_change(new_role, changer_user)
    return unless Rails.env.development?
    
    puts "=== DEBUG ROLE CHANGE ==="
    puts "Usuario actual: #{email} (#{role} -> #{role_before_type_cast})"
    puts "Nuevo rol: #{new_role} (#{new_role.class})"
    puts "Changer: #{changer_user.email} (#{changer_user.role} -> #{changer_user.role_before_type_cast})"
    
    new_role_int = case new_role
    when String then User.roles[new_role]
    when Symbol then User.roles[new_role.to_s]
    when Integer then new_role
    else nil
    end
    
    puts "Nuevo rol int: #{new_role_int}"
    puts "Puede cambiar?: #{can_change_role_to?(new_role, changer_user)}"
    puts "========================="
  end
  
  # ✅ ATRIBUTO PARA TRACKEAR QUIÉN HACE EL CAMBIO
  attr_accessor :role_changer
  
  private
  
  def set_default_role
    self.role ||= Role.find_by(name: 'client')
  end
  
  def role_change_authorization
    return unless role_changed? && persisted?
    
    if role_changer.nil?
      errors.add(:role, "Debe especificar quién autoriza el cambio de rol")
      return
    end
    
    # Convertir role a string para la comparación
    new_role_for_validation = role.to_s
    unless can_change_role_to?(new_role_for_validation, role_changer)
      errors.add(:role, "No tienes permisos para asignar este rol a este usuario")
    end
  end
  
  def prevent_unauthorized_role_change
    return unless role_changed? && persisted?
    
    if role_changer && !can_change_role_to?(role.to_s, role_changer)
      Rails.logger.warn "🚨 INTENTO DE CAMBIO DE ROL NO AUTORIZADO:"
      Rails.logger.warn "   Usuario objetivo: #{email} (#{role_was} -> #{role})"
      Rails.logger.warn "   Usuario que intenta: #{role_changer&.email} (#{role_changer&.role})"
      Rails.logger.warn "   Timestamp: #{Time.current}"
      
      throw :abort
    end
  end
end
