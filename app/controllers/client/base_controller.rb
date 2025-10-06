class Client::BaseController < ApplicationController
    layout 'application'
    before_action :authenticate_user!
    before_action :ensure_client_access

    private

    def ensure_client_access
      unless current_user.role&.name == "client"
        redirect_to root_path, alert: "Acceso restringido a clientes"
      end
    end
end
