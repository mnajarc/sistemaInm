class Admin::BaseController < ApplicationController
  #layout 'admin'  # ← Usar layout sin JS

  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :ensure_admin


  private

  def ensure_admin
    redirect_to root_path, alert: "Acceso denegado" unless current_user&.admin?
  end

  def authorize_admin!
    redirect_to root_path, alert: 'No autorizado' unless current_user.admin?
  end
end
