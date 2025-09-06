# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization  # ✅ CORREGIR: Usar Authorization, no solo Pundit
  
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Proteger todas las acciones por defecto
  after_action :verify_authorized, except: [:index, :show]
  after_action :verify_policy_scoped, only: :index
  
  # Rescatar errores de autorización
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  protected
  
  def pundit_user
    current_user
  end
  
  def after_sign_in_path_for(resource)
    Rails.logger.debug "REDIRECT DEBUG: User #{resource.email} signed in, redirecting to root path"
    root_path
  end
  
  private
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end
  
  def user_not_authorized
    flash[:alert] = "No tienes permisos para realizar esta acción"
    redirect_to(request.referrer || root_path)
  end
end
