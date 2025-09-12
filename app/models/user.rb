class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  
  # anteriormente se tenía en memoria y se cambia por una tabla para dar mayor flexibilidad al modelo
  belongs_to :role

  has_many :properties, dependent: :destroy
  has_one :client, dependent: :nullify
 
  validates :role, presence: true
  validates :role_id, presence: true
  validate :role_exists
  validate :role_change_authorization, if: :role_changed?
  
  after_initialize :set_default_role, if: :new_record?
  before_update :prevent_unauthorized_role_change
  
  # ✅ SCOPE PARA USUARIOS GESTIONABLES
  scope :manageable_by, ->(manager) { 
    joins(:role).where('roles.level > ?', manager.role&.level || 999)
  } 
  
  # ✅ NIVELES DE ROL (para lógica de interfaz)
  def role_level
    role&.level || 999
  end
  
  # ✅ VERIFICAR SI PUEDE SER GESTIONADO POR OTRO USUARIO
  def can_be_managed_by?(manager_user)
    return false unless manager_user
    self.role.level > manager_user.role.level
  end
  
  # ✅ VERIFICAR SI SE PUEDE CAMBIAR A UN ROL ESPECÍFICO
  def can_change_role_to?(new_role_name, changer_user)
    return false unless changer_user
    
    new_role = Role.find_by(name: new_role_name)
    return false unless new_role

    # ✅ CORREGIR: SuperAdmin (nivel 0) puede asignar cualquier rol
    return true if changer_user.superadmin?
    
    # Para otros roles: solo pueden asignar roles de nivel MAYOR (menos privilegios)
    changer_user.role&.level && new_role.level &&
    changer_user.role.level < new_role.level
  end
  
  # ✅ MÉTODOS DE VERIFICACIÓN DE ROL
  def admin_or_above?
    role&.level && role.level <= 10
  end

  def agent_or_above?
    role&.level && role.level <= 20
  end

  def superadmin?
    role&.name == 'superadmin'
  end

  def admin?
    role&.name == 'admin'
  end

  def agent?
    role&.name == 'agent'
  end
  
  def client?
    role&.name == 'client'
  end

  def admin_or_above?
    %w[superadmin admin].include?(role&.name)
  end
  
  def can_manage_user?(other_user)
    role&.level && other_user.role&.level &&
    role.level < other_user.role.level
  end

  
  # ✅ VERIFICAR SI ESTÁ ACTIVO
  def active?
    respond_to?(:active) ? (active.nil? ? true : active) : true
  end
  
  # ✅ NOMBRE DEL ROL EN ESPAÑOL
    def role_name
    role&.display_name || 'Sin rol'
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
  # ✅ AGREGAR MÉTODO DE CONVENIENCIA:
  def client_record
    client || Client.find_by(email: email)
  end
  
  
  # ✅ ATRIBUTO PARA TRACKEAR QUIÉN HACE EL CAMBIO
  attr_accessor :role_changer
  
  private
  
  def set_default_role
    self.role ||= Role.find_by(name: 'client')
  end
  
  def role_exists
  errors.add(:role, "debe existir") unless role&.persisted?
  end

  def role_change_authorization
    return unless role_changed? && persisted?
    
    if role_changer.nil?
      errors.add(:role, "Debe especificar quién autoriza el cambio de rol")
      return
    end
    
    # Convertir role a string para la comparación
    new_role_for_validation = role.name
    unless can_change_role_to?(new_role_for_validation, role_changer)
      errors.add(:role, "No tienes permisos para asignar este rol a este usuario")
    end
  end
  
  def prevent_unauthorized_role_change
    return unless role_changed? && persisted?
    
    if role_changer && !can_change_role_to?(role.name, role_changer)
      Rails.logger.warn "🚨 INTENTO DE CAMBIO DE ROL NO AUTORIZADO:"
      Rails.logger.warn "   Usuario objetivo: #{email} (#{role_was} -> #{role.name})"
      Rails.logger.warn "   Usuario que intenta: #{role_changer&.email} (#{role_changer&.role.name})"
      Rails.logger.warn "   Timestamp: #{Time.current}"
      
      throw :abort
    end
  end
end
