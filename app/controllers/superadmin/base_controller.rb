class Superadmin::BaseController < ApplicationController
  before_action :ensure_superadmin
  
  def index
    @stats = {
      total_users: User.count,
      superadmins: User.superadmin.count,
      admins: User.admin.count,
      agents: User.agent.count,
      clients: User.client.count,
      total_menu_items: MenuItem.count,
      active_menu_items: MenuItem.active.count,
      total_roles: Role.count,
      system_roles: Role.system_roles.count
    }
    
    @recent_role_changes = recent_role_changes
  end
  
  private
  
  def ensure_superadmin
    unless current_user&.superadmin?
      redirect_to root_path, alert: "Acceso restringido solo a SuperAdministradores"
    end
  end
  
  def recent_role_changes
    User.where('updated_at > ?', 24.hours.ago)
        .where.not(role: :client)
        .order(updated_at: :desc)
        .limit(10)
  end
end

