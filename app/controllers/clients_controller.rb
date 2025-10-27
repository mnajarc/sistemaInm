# app/controllers/clients_controller.rb
class ClientsController < ApplicationController
  include Pundit::Authorization
  before_action :authenticate_user!

  def create
    @client = Client.new(client_params)
    @client.active = true # Por defecto activo

    authorize @client

    if @client.save
      # ✅ Si es AJAX, retornar JSON
      if request.xhr? || request.format.json?
        render json: {
          id: @client.id,
          name: @client.name,
          display_name: @client.display_name,
          email: @client.email
        }, status: :created
      else
        redirect_to admin_clients_path, notice: 'Cliente creado exitosamente'
      end
    else
      if request.xhr? || request.format.json?
        render json: { errors: @client.errors.full_messages }, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def client_params
    params.require(:client).permit(:name, :email, :phone, :address, :active)
  end
end
