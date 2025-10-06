class Superadmin::BaseController < BaseController
  layout 'application'
  before_action :ensure_superadmin

  def index
    role_counts = User.joins(:role)
                    .group("roles.name")
                    .count
    @stats = {
      total_users: User.count,
      superadmins: role_counts["superadmin"] || 0,
      admins: role_counts["admin"] || 0,
      agents: role_counts["agent"] || 0,
      clients: role_counts["client"] || 0,
      total_menu_items: MenuItem.count,
      active_menu_items: MenuItem.active.count,
      total_roles: Role.count,
      system_roles: Role.system_roles.count
    }

    @recent_role_changes = recent_role_changes
  end

  private

  def ensure_superadmin_access
    unless current_user&.superadmin?
      flash[:alert] = "Acceso denegado: Se requieren permisos de SuperAdministrador"
      redirect_to root_path
    end
  end

  def ensure_superadmin
    unless current_user&.superadmin?
      redirect_to root_path, alert: "Acceso restringido solo a SuperAdministradores"
    end
  end

  def verify_policy_scoped
    return if action_name == 'index'  # Saltar verificación en dashboard
    super  # Verificación normal para otras acciones
  end

  def recent_role_changes
    User.joins(:role)
      .where("users.updated_at > ?", 24.hours.ago)
      .where.not(roles: { name: "client" })
      .includes(:role)  # Para evitar N+1 queries
      .order("users.updated_at DESC")
      .limit(10)
  end
end
