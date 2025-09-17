class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def after_sign_in_path_for(resource)
    # Redirigir según el rol del usuario
    case resource.role&.name
    when 'client'
      client_root_path
    when 'agent', 'admin', 'superadmin'
      root_path
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role])
  end
end
