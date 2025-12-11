class ClientsController < ApplicationController
  before_action :set_client, only: [:show, :edit, :update, :destroy]
  before_action :set_form, only: [:new, :create, :edit, :update]

  # ========================================
  # GET /clients/new?form_id=58
  # ========================================
  def new
    @client = Client.new
    # @form ya está seteado por before_action
    # Si no viene form_id, @form será nil (y eso está bien)
  end

  # ========================================
  # POST /clients
  # ========================================
  def create
    @client = Client.new(client_params)
    
    if @client.save
      # ✅ Actualizar el formulario con los datos del cliente
      if @form.present?
        update_form_from_client(@client, @form)
      end
      
      # Redirigir al formulario si viene form_id, sino a show del cliente
      redirect_to @form || @client, notice: '✅ Cliente guardado exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ========================================
  # GET /clients/:id
  # ========================================
  def show
    # @client ya está seteado por before_action
  end


  def edit
    @form = InitialContactForm.find(params[:form_id]) if params[:form_id]
    
    # ✅ LÓGICA INTELIGENTE: Cargar o crear cliente
    if @form.present? && @client.nil?
      email = @form.general_conditions&.dig('owner_email')
      
      if email.present?
        # Buscar por email o crear
        @client = Client.find_by(email: email)
        
        unless @client
          # Crear cliente desde datos del formulario
          @client = Client.from_initial_contact_form(@form)
          @client.save if @client.valid?
        end
      end
    end
  end



  # ========================================
  # PATCH/PUT /clients/:id
  # ========================================
  def update
    if @client.update(client_params)
      # ✅ Actualizar el formulario con los datos modificados
      if @form.present?
        update_form_from_client(@client, @form)
      end
      
      redirect_to @form || @client, notice: '✅ Cliente actualizado exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ========================================
  # DELETE /clients/:id
  # ========================================
  def destroy
    @client.destroy
    
    # Si vino desde un formulario, volver a él
    # Sino, volver al listado de clientes
    redirect_to clients_url, notice: '✅ Cliente eliminado'
  end

  private

  # ========================================
  # CALLBACKS PRIVADOS
  # ========================================

  def set_client
    @client = Client.find(params[:id])
  end

  def set_form
    # ✅ CORREGIDO: Ahora es seguro si form_id es nil
    @form = InitialContactForm.find(params[:form_id]) if params[:form_id].present?
  end

  # ========================================
  # STRONG PARAMETERS
  # ========================================

  def client_params
    params.require(:client).permit(
      :full_name,
      :phone,
      :email,
      :civil_status,
      :marriage_regime_id,
      :notes
    )
  end

  # ========================================
  # HELPER: Actualizar formulario
  # ========================================

  def update_form_from_client(client, form)
    # Obtener o crear general_conditions
    general_conditions = form.general_conditions || {}
    
    # Actualizar con los datos del cliente
    general_conditions.merge!(
      'owner_or_representative_name' => client.full_name,
      'owner_phone' => client.phone,
      'owner_email' => client.email,
      'civil_status' => client.civil_status,
      'marriage_regime_id' => client.marriage_regime_id,
      'notes' => client.notes
    )
    
    # Guardar los cambios
    form.update(general_conditions: general_conditions)
  end
end
