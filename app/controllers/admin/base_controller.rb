class Admin::BaseController < ApplicationController
  before_action :ensure_admin!
  layout 'admin'
  
  private
  
  def ensure_admin!
    admin_level = get_config('roles.admin_max_level', 10)
    authorize_minimum_level!(admin_level)
  end
  
  def load_manageable_resources
    # Recursos que puede gestionar según configuración
    manageable_config = get_config('admin.manageable_resources', {
      'users' => true,
      'properties' => true,
      'business_transactions' => true,
      'documents' => true,
      'catalogs' => true
    })
    
    @manageable_resources = manageable_config.select { |_, enabled| enabled }.keys
  end
end
