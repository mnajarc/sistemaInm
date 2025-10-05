class ApplicationController < ActionController::Base
  include ConfigurableController
  include Pundit::Authorization  # ← AGREGAR ESTA LÍNEA
  
  protect_from_forgery with: :exception
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Manejo de errores de autorización Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  protected
  
  def after_sign_in_path_for(resource)
    # Rutas configurables por rol
    role_routes = get_config('routes.role_redirects', {
      'client' => 'client_root_path',
      'agent' => 'root_path', 
      'admin' => 'root_path',
      'superadmin' => 'superadmin_root_path'
    })
    
    route_method = role_routes[resource.role&.name] || 'root_path'
    
    begin
      send(route_method)
    rescue NoMethodError
      root_path
    end
  end
  
  def after_sign_out_path_for(resource_or_scope)
    sign_out_redirect = get_config('routes.sign_out_redirect', 'new_user_session_path')
    
    begin
      send(sign_out_redirect)
    rescue NoMethodError
      new_user_session_path
    end
  end
  
  # Método helper para verificar permisos configurables
  def authorize_minimum_level!(required_level)
    unless role_level_sufficient?(required_level)
      required_role = Role.where('level <= ?', required_level).order(:level).first
      flash[:alert] = "Acceso denegado. Se requiere nivel #{required_role&.display_name || required_level} o superior."
      redirect_to root_path
    end
  end
  
  def authorize_role_names!(allowed_role_names)
    return if allowed_role_names.include?(current_user&.role&.name)
    
    flash[:alert] = "Acceso denegado. Roles permitidos: #{allowed_role_names.join(', ')}"
    redirect_to root_path
  end
  
  private
  
  def configure_permitted_parameters
    permitted_keys = get_config('auth.permitted_signup_keys', [:role])
    devise_parameter_sanitizer.permit(:sign_up, keys: permitted_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: permitted_keys)
  end
  
  def user_not_authorized
    flash[:alert] = "No tienes permisos para realizar esta acción."
    redirect_to(request.referrer || root_path)
  end
end