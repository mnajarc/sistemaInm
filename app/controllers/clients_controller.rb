class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: [:show, :edit, :update, :destroy]
  before_action :set_form, only: [:new, :create, :edit, :update]
  before_action :load_form_data, only: [:new, :create, :edit, :update]

  # ========================================
  # GET /clients/new?form_id=58
  # ========================================
  def new
    @client = Client.new
    @client.client_addresses.build(
      address_type: "fiscal",
      address: Address.new(country: "México")
    )
    @client.client_addresses.build(
      address_type: "particular",
      address: Address.new(country: "México")
    )
    load_form_data

    build_default_addresses
      # @form ya está seteado por before_action
      # Si no viene form_id, @form será nil (y eso está bien)
    end

  # ========================================
  # POST /clients
  # ========================================
  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save
        if @form.present?
          update_form_from_client(@client, @form)
          format.html { redirect_to @form, notice: '✅ Cliente guardado' }
        elsif params[:return_to].present?
          format.turbo_stream do
            render turbo_stream: turbo_stream.action(
              :append,
              "newClientModal",
              "<script>
                const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('newClientModal'));
                modal.hide();
                alert('✅ Cliente #{@client.display_name} creado. Búscalo en el formulario.');
              </script>".html_safe
            )
          end
          format.html { redirect_to params[:return_to], notice: "✅ Cliente creado" }
        else
          format.html { redirect_to @client, notice: '✅ Cliente guardado' }
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "client_form_errors",
            partial: "clients/form_errors",
            locals: { client: @client }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
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
      email = @form.general_conditions&.dig("owner_email")

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

    # ✅ Asegurar domicilios mínimo (si ya hay @client)
    if @client.present? && @client.client_addresses.empty?
      @client.client_addresses.build(
        address_type: "fiscal",
        address: Address.new(country: "México")
      )
      @client.client_addresses.build(
        address_type: "particular",
        address: Address.new(country: "México")
      )
    end

    # ✅ Cargar países para los selects
    load_form_data
    build_default_addresses
  end






  # ========================================
  # PATCH/PUT /clients/:id
  # ========================================
  def update
    if @client.update(client_params)
      update_form_from_client(@client, @form) if @form.present?

      if params[:return_to].present?
        redirect_to params[:return_to], notice: '✅ Cliente actualizado exitosamente'
      else
        redirect_to(@form || @client, notice: '✅ Cliente actualizado exitosamente')
      end
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

  # ========================================
  # GET /clients/search.json?q=martin
  # ========================================
  def search
    authorize Client  # Si usas Pundit

    query = params[:q].to_s.strip
    
    if query.length < 2
      render json: []
      return
    end

    # Búsqueda por nombre o email
    clients = Client
      .search_by_full_name_or_email(query)
      .order(:first_surname, :first_names)
      .limit(10)
      .map do |client|
        {
          id: client.id,
          display_name: client.display_name,
          email: client.email,
          phone: client.phone
        }
      end

    render json: clients
  rescue => e
    Rails.logger.error "❌ Error en clients#search: #{e.message}"
    render json: { error: "Error al buscar clientes" }, status: :internal_server_error
  end



  private

  # ========================================
  # CALLBACKS PRIVADOS
  # ========================================

  def set_client
    @client = Client.find(params[:id])
    authorize @client  # Si usas Pundit
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
      :first_names,
      :first_surname,
      :second_surname,
      :phone,
      :email,
      :civil_status,
      :rfc,
      :tax_regime,
      :nationality_country_id,
      :birth_country_id,
      :marriage_regime_id,
      :notes,
      client_addresses_attributes: [
        :id,
        :address_type,
        :_destroy,
        # nested address
        address_attributes: [
          :id,
          :street,
          :exterior_number,
          :interior_number,
          :neighborhood,
          :municipality,
          :state,
          :country,
          :postal_code,
          :notes
        ]
      ]
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

  def load_form_data
    @countries = Country.ordered
  end

  def build_default_addresses
    return unless @client.present?

    if @client.client_addresses.empty?
      @client.client_addresses.build(
        address_type: "fiscal",
        address: Address.new(country: "México")
      )
      @client.client_addresses.build(
        address_type: "particular",
        address: Address.new(country: "México")
      )
    else
      @client.client_addresses.each do |ca|
        ca.build_address if ca.address.nil?
      end
    end
  end


end
