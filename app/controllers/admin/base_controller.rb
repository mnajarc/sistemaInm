class Admin::BaseController < BaseController
  layout 'admin'  # ✅ USAR LAYOUT ESPECÍFICO ADMIN
  before_action :ensure_admin_access

  private

  def ensure_admin_access
    unless current_user&.admin_or_above?
      flash[:alert] = "Acceso denegado: Se requieren permisos de administrador"
      redirect_to root_path
    end
  end
end
