class PropertyPolicy < ApplicationPolicy
  include Configurable
  
  def index?
    # Todos los usuarios autenticados pueden ver el índice
    user.present?
  end
  
  def show?
    # Todos pueden ver propiedades individuales
    user.present?
  end
  
  def create?
    # Solo agentes o superiores pueden crear propiedades
    return false unless user&.role
    user.role.level <= get_config('roles.agent_max_level', 20)
  end
  
  def new?
    create?
  end
  
  def update?
    # Solo el propietario, agentes o superiores pueden actualizar
    return true if user_owns_property?
    return true if user_can_manage_properties?
    false
  end
  
  def edit?
    update?
  end
  
  def destroy?
    # Solo el propietario, admins o superiores pueden eliminar
    return true if user_owns_property?
    return true if user_is_admin_or_above?
    false
  end
  
  # Scope para filtrar propiedades según el usuario
  class Scope < Scope
    def resolve
      case user&.role&.name
      when *superadmin_role_names, *admin_role_names
        # SuperAdmin y Admin ven todas las propiedades
        scope.all
      when *agent_role_names
        # Agentes ven todas las propiedades
        scope.all
      when *client_role_names
        # Clientes solo ven propiedades publicadas
        scope.where.not(published_at: nil)
      else
        # Sin rol o rol desconocido: solo propiedades públicas
        scope.where.not(published_at: nil)
      end
    end
    
    private
    
    def superadmin_role_names
      get_config('roles.superadmin_names', ['superadmin'])
    end
    
    def admin_role_names
      get_config('roles.admin_names', ['admin'])
    end
    
    def agent_role_names
      get_config('roles.agent_names', ['agent'])
    end
    
    def client_role_names
      get_config('roles.client_names', ['client'])
    end
    
    def get_config(key, default = nil)
      if defined?(SystemConfiguration)
        SystemConfiguration.get(key, default)
      else
        default
      end
    rescue => e
      Rails.logger.error "Error getting config in PropertyPolicy::Scope: #{e.message}"
      default
    end
  end
  
  private
  
  def user_owns_property?
    record.user_id == user&.id
  end
  
  def user_can_manage_properties?
    return false unless user&.role
    user.role.level <= get_config('roles.agent_max_level', 20)
  end
  
  def user_is_admin_or_above?
    return false unless user&.role
    user.role.level <= get_config('roles.admin_max_level', 10)
  end
  
  def user_is_superadmin?
    return false unless user&.role
    superadmin_names = get_config('roles.superadmin_names', ['superadmin'])
    superadmin_names.include?(user.role.name)
  end
end