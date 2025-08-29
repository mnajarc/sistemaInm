class ApplicationController < ActionController::Base
  # Rate limiting más específico por tipo de acción
  rate_limit to: 10, within: 1.minute, only: [:create], name: "create_actions"
  rate_limit to: 50, within: 1.minute, only: [:update, :destroy], name: "modify_actions"  
  rate_limit to: 100, within: 1.minute, except: [:create, :update, :destroy], name: "read_actions"

  protect_from_forgery with: :exception
  before_action :authenticate_user!
  allow_browser versions: :modern
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
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
end
