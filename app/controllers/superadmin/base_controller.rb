class Superadmin::BaseController < ApplicationController
  include ConfigurableController
  
  before_action :ensure_superadmin!
  layout 'superadmin'
  
  def index
    @stats = load_dashboard_statistics
    @recent_activities = load_recent_activities
    @system_health = check_system_health
  rescue => e
    Rails.logger.error "Error loading SuperAdmin dashboard: #{e.message}"
    @stats = default_stats
    @recent_activities = {}
    @system_health = { error: e.message }
    @recent_role_changes = []  # Important: always fallback to empty array
    flash.now[:alert] = "Error cargando estadísticas del dashboard"
  end
  
  private

  def load_recent_role_changes
    # Example query, customize según modelo RoleChangeLog o audit trail que use
    RoleChangeLog.order(changed_at: :desc).limit(10)
   rescue => e
    Rails.logger.error "Error loading recent role changes: #{e.message}"
    []
  end

  def ensure_superadmin!
    superadmin_level = get_config('roles.superadmin_max_level', 0)
    authorize_minimum_level!(superadmin_level)
   rescue => e
    Rails.logger.error "Error checking superadmin access: #{e.message}"
    redirect_to root_path, alert: 'Acceso denegado'
  end
  
  def load_dashboard_statistics
    {
      total_users: safe_count(User),
      active_users: safe_count(User.where(active: true)),
      total_properties: safe_count(Property),
      active_transactions: safe_count(BusinessTransaction.joins(:business_status).where(business_statuses: { name: ['available', 'reserved'] })),
      roles_count: safe_count(Role.where(active: true)),
      menu_items_count: safe_count(MenuItem.where(active: true)),
      configurations_count: safe_count(SystemConfiguration.where(active: true)),
      agents_count: safe_count(User.joins(:role).where(roles: { name: 'agent' })),
      clients_count: safe_count(User.joins(:role).where(roles: { name: 'client' }))
    }
   rescue => e
    Rails.logger.error "Error loading dashboard statistics: #{e.message}"
    default_stats
  end
  
  def load_recent_activities
    max_activities = get_config('dashboard.max_recent_activities', 5)
    
    {
      new_users: safe_recent(User, max_activities),
      recent_transactions: safe_recent(BusinessTransaction, max_activities),
      recent_properties: safe_recent(Property, max_activities)
    }
   rescue => e
    Rails.logger.error "Error loading recent activities: #{e.message}"
    { new_users: [], recent_transactions: [], recent_properties: [] }
  end
  
  def check_system_health
    health_checks = get_config('system.health_checks', [
      'database_connection',
      'active_users', 
      'system_configurations',
      'role_permissions'
    ])
    
    results = {}
    
    health_checks.each do |check|
      results[check] = perform_health_check(check)
    end
    
    results
   rescue => e
    Rails.logger.error "Error checking system health: #{e.message}"
    { error: e.message }
  end
  
  def perform_health_check(check_name)
    case check_name
    when 'database_connection'
      User.connection.active? ? 'OK' : 'ERROR'
    when 'active_users'
      User.where(active: true).exists? ? 'OK' : 'WARNING'
    when 'system_configurations'
      if defined?(SystemConfiguration)
        SystemConfiguration.where(active: true).count > 0 ? 'OK' : 'WARNING'
      else
        'N/A'
      end
    when 'role_permissions'
      Role.joins(:role_menu_permissions).exists? ? 'OK' : 'WARNING'
    else
      'UNKNOWN'
    end
   rescue => e
    Rails.logger.error "Health check failed for #{check_name}: #{e.message}"
    'ERROR'
  end
  
  # Métodos helper para manejo seguro de errores
  def safe_count(model_or_relation)
    model_or_relation.count
   rescue => e
    Rails.logger.error "Error counting #{model_or_relation}: #{e.message}"
    0
  end
  
  def safe_recent(model, limit)
    model.order(created_at: :desc).limit(limit)
   rescue => e
    Rails.logger.error "Error loading recent #{model}: #{e.message}"
    []
  end
  
  def default_stats
    {
      total_users: 0,
      active_users: 0,
      total_properties: 0,
      active_transactions: 0,
      roles_count: 0,
      menu_items_count: 0,
      configurations_count: 0,
      agents_count: 0,
      clients_count: 0
    }
  end
  
  # Método helper para obtener configuraciones con fallback
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
end