# app/controllers/admin/instance_settings_controller.rb
module Admin
  class InstanceSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_instance_admin
    before_action :check_internal_network_only

    def edit
      @config = InstanceConfig.current
    end

    def update
      @config = InstanceConfig.current
      if @config.update(config_params)
        redirect_to admin_instance_settings_edit_path, 
                   notice: "Configuración de instancia actualizada"
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def authorize_instance_admin
      unless current_user&.role&.name == 'superadmin'
        redirect_to root_path, alert: "No tienes permiso para acceder a esta sección"
      end
    end

    def check_internal_network_only
      # Permitir SOLO desde red privada (comentar si estás en desarrollo local)
      allowed_networks = ['127.0.0.1', '::1']
      allowed_networks += ENV['PRIVATE_NETWORKS']&.split(',') || []
      
      unless allowed_networks.include?(request.remote_ip)
        render json: { error: 'Acceso denegado: Solo red privada' }, status: :forbidden
      end
    end

    def config_params
      params.require(:instance_config).permit(
        :app_name, :app_logo, :app_primary_color, 
        :app_favicon, :app_tagline, :organization_name
      )
    end
  end
end
