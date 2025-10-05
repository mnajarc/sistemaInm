module ConfigurableController
  extend ActiveSupport::Concern
  
  included do
    before_action :load_system_configurations, if: :user_signed_in?
  end
  
  private
  
  def load_system_configurations
    @system_config = load_configs_by_category
    @current_user_config = current_user_configurations if current_user
  rescue => e
    Rails.logger.error "Error loading system configurations: #{e.message}"
    @system_config = {}
    @current_user_config = {}
  end
  
  def load_configs_by_category
    if defined?(SystemConfiguration)
      SystemConfiguration.active.group_by(&:category)
    else
      {}
    end
  rescue => e
    Rails.logger.error "Error grouping configurations: #{e.message}"
    {}
  end
  
  def current_user_configurations
    return {} unless current_user&.role
    
    {
      max_role_level: current_user.role.level,
      permissions: current_user.role.role_menu_permissions.includes(:menu_item),
      accessible_statuses: accessible_business_statuses,
      accessible_operations: accessible_operation_types,
      role_name: current_user.role.name
    }
  rescue => e
    Rails.logger.error "Error loading user configurations: #{e.message}"
    {}
  end
  
  def accessible_business_statuses
    if defined?(BusinessStatus)
      min_level = current_user&.role&.level || 999
      BusinessStatus.where('minimum_role_level >= ?', min_level)
    else
      BusinessStatus.none if defined?(BusinessStatus)
    end
  rescue => e
    Rails.logger.error "Error loading accessible business statuses: #{e.message}"
    []
  end
  
  def accessible_operation_types  
    if defined?(OperationType)
      OperationType.where(active: true).order(:sort_order)
    else
      []
    end
  rescue => e
    Rails.logger.error "Error loading accessible operation types: #{e.message}"
    []
  end
  
  def get_config(key, default = nil)
    if defined?(SystemConfiguration)
      SystemConfiguration.get(key, default)
    else
      default
    end
  rescue => e
    Rails.logger.error "Error getting config #{key}: #{e.message}"
    default
  end
  
  def role_level_sufficient?(required_level)
    return false unless current_user&.role
    current_user.role.level <= required_level
  rescue => e
    Rails.logger.error "Error checking role level: #{e.message}"
    false
  end
  
  def authorize_minimum_level!(required_level)
    unless role_level_sufficient?(required_level)
      required_role = Role.where('level <= ?', required_level).order(:level).first
      flash[:alert] = "Acceso denegado. Se requiere nivel #{required_role&.display_name || required_level} o superior."
      redirect_to root_path
    end
  rescue => e
    Rails.logger.error "Error in authorize_minimum_level: #{e.message}"
    redirect_to root_path, alert: 'Error de autorización'
  end
  
  def authorize_role_names!(allowed_role_names)
    return if allowed_role_names.include?(current_user&.role&.name)
    
    flash[:alert] = "Acceso denegado. Roles permitidos: #{allowed_role_names.join(', ')}"
    redirect_to root_path
  rescue => e
    Rails.logger.error "Error in authorize_role_names: #{e.message}"
    redirect_to root_path, alert: 'Error de autorización'
  end
end