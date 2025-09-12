class Client::BaseController < ApplicationController
  layout 'client'
  before_action :ensure_client_access

  private

  def ensure_client_access
    # Si no está autenticado, Devise se encarga
    return unless user_signed_in?
    
    # Solo verificar rol si está autenticado
    unless current_user.client?
      flash[:alert] = 'Acceso restringido a clientes'
      redirect_to root_path
    end
  end

  def current_client
    @current_client ||= if current_user&.client?
                          current_user.client || 
                          Client.find_by(email: current_user.email) ||
                          Client.find_or_create_for_user(current_user)
                        end
  end
  helper_method :current_client
end
