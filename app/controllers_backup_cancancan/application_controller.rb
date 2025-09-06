class ApplicationController < ActionController::Base
  # Rate limiting más específico por tipo de acción
  # rate_limit to: 10, within: 1.minute, only: [:create], name: "create_actions",
           # with: -> { 
             # Rails.logger.warn "Rate limit exceeded for IP: #{request.remote_ip}"
             # head :too_many_requests 
           # }
  # rate_limit to: 50, within: 1.minute, only: [:update, :destroy], name: "modify_actions"  
  # rate_limit to: 100, within: 1.minute, except: [:create, :update, :destroy], name: "read_actions"

  include Pundit::Authorization

    # Proteger todas las acciones por defecto
  after_action :verify_authorized, except: [:index, :show]
  after_action :verify_policy_scoped, only: :index

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  allow_browser versions: :modern

    # Rescatar errores de autorización
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
 
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end
  
  protected
  
  def pundit_user
    current_user
  end
  

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end

  protected

  def after_sign_in_path_for(resource)
    Rails.logger.debug "REDIRECT DEBUG: User #{resource.email} signed in, redirecting to root path"
    root_path
  end
    
  def user_not_authorized
    flash[:alert] = "No tienes permisos para realizar esta acción"
    redirect_to(request.referrer || root_path)
  end

end

