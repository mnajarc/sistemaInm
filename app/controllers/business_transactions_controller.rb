class BusinessTransactionsController < BaseController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy transfer_agent]

  def index
    @transactions = if current_user.client?
                      current_user.client.offered_transactions
    elsif current_user.agent_or_above?
                      policy_scope(BusinessTransaction)
    else
                      BusinessTransaction.none
    end
  end

  def show
    authorize @transaction
  end

  def new
    @transaction = BusinessTransaction.new
    authorize @transaction
    
    # ✅ Preparar objetos anidados
    @transaction.build_property # Para crear nueva propiedad si es necesario
    @transaction.co_owners.build(percentage: 100.0, role: 'propietario') # Al menos uno
    
    load_form_data
    
        @clients = Client.active.order(:name)
  end


  def create
    @transaction = BusinessTransaction.new(transaction_params)
    
    if params[:property_option] == "new"
      property_attrs = params[:business_transaction][:property_attributes]
      if property_attrs && property_attrs[:address].present?
        @transaction.build_property(property_attrs.permit!.merge(user: current_user))
      else
        @transaction.errors.add(:base, "Debes completar los datos de la propiedad")
        load_form_data
        render :new, status: :unprocessable_entity
        return
      end
    elsif params[:property_option] == "existing"
      @transaction.property_attributes = nil
    end

    authorize @transaction
    assign_agents_by_role if respond_to?(:assign_agents_by_role, true)

    # ✅ AGREGAR ESTE BLOQUE:
    if @transaction.business_transaction_co_owners.empty? && @transaction.offering_client_id.present?
      @transaction.business_transaction_co_owners.build(
        client_id: @transaction.offering_client_id,
        person_name: @transaction.offering_client&.display_name,
        percentage: 100,
        role: 'vendedor'
      )
      puts "✅ Auto-agregado offering_client como copropietario"
    end

    if @transaction.save
      redirect_to @transaction, notice: "Transacción creada exitosamente"
    else
      puts "❌ ERRORES: #{@transaction.errors.full_messages.inspect}"
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  
  def edit
    authorize @transaction
    
    # Asegurar que tiene al menos un copropietario
    if @transaction.co_owners.empty?
      @transaction.co_owners.build(percentage: 100.0, role: 'propietario')
    end
    
    load_form_data
  end

  def update
    authorize @transaction
    
    if current_user.admin_or_above? && params[:business_transaction][:current_agent_id].present?
      reassign_agent
    end
    
    if current_user.admin_or_above? && params[:business_transaction][:selling_agent_id].present?
      reassign_selling_agent
    end
    
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: "Transacción actualizada exitosamente"
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @transaction
    @transaction.destroy
    redirect_to business_transactions_path, notice: "Transacción eliminada exitosamente"
  end

  def transfer_agent
    authorize @transaction, :update?
    new_agent = User.find(params[:new_agent_id])
    @transaction.transfer_to_agent!(new_agent, params[:reason], current_user)
    redirect_to @transaction, notice: "Agente transferido correctamente"
  end

  def export_documents
    service = TransactionExportService.new(@business_transaction, base_path: export_base_path)
    result = service.export
    
    if result[:success]
      redirect_to @business_transaction, 
                  notice: "📂 #{result[:message]}"
    else
      redirect_to @business_transaction, 
                  alert: "❌ #{result[:message]}"
    end
  end


  private

  def export_base_path
    # Cambiar según tu configuración
    Rails.env.production? ? '/mnt/nas_docs' : Rails.root.join('tmp', 'exports')
  end

  def set_transaction
    @transaction = BusinessTransaction.find(params[:id])
  end

  def assign_agents_by_role
    case current_user.role.name
    when 'agent'
      @transaction.listing_agent = current_user
      @transaction.current_agent = current_user
      
    when 'admin', 'superadmin'
      if params[:business_transaction][:current_agent_id].present?
        assigned_agent = User.find(params[:business_transaction][:current_agent_id])
        if assigned_agent.agent?
          @transaction.listing_agent = assigned_agent
          @transaction.current_agent = assigned_agent
        else
          @transaction.errors.add(:current_agent_id, "El usuario seleccionado no es un agente")
          return false
        end
      else
        first_agent = User.joins(:agent).where(agents: { is_active: true }).first
        if first_agent
          @transaction.listing_agent = first_agent
          @transaction.current_agent = first_agent
        else
          @transaction.errors.add(:base, "No hay agentes activos disponibles para asignar")
          return false
        end
      end
      
      if params[:business_transaction][:selling_agent_id].present?
        selling_agent = User.find(params[:business_transaction][:selling_agent_id])
        if selling_agent.agent?
          @transaction.selling_agent = selling_agent
        else
          @transaction.errors.add(:selling_agent_id, "El agente vendedor seleccionado no es válido")
          return false
        end
      end
    end
    
    true
  end

  def reassign_agent
    if params[:business_transaction][:current_agent_id].present?
      new_agent = User.find(params[:business_transaction][:current_agent_id])
      if new_agent.agent?
        @transaction.current_agent = new_agent
      end
    end
  end

  def reassign_selling_agent
    if params[:business_transaction][:selling_agent_id].present?
      new_selling_agent = User.find(params[:business_transaction][:selling_agent_id])
      if new_selling_agent.agent?
        @transaction.selling_agent = new_selling_agent
      end
    end
  end

  def load_form_data
    @clients = Client.active.order(:name)
    
    @properties = if current_user.admin_or_above?
                    Property.includes(:property_type, :user).order(:address)
                  else
                    Property.where(user: current_user).includes(:property_type)
                  end
    
    @operation_types = OperationType.active.order(:sort_order)
    @business_statuses = BusinessStatus.active.order(:sort_order)
    @property_types = PropertyType.active.order(:sort_order)
    @co_ownership_types = CoOwnershipType.active.order(:sort_order)
    @co_ownership_roles = CoOwnershipRole.active.order(:sort_order)
    @roles = @co_ownership_roles.pluck(:display_name, :name)
    
    if current_user.admin_or_above?
      @available_agents = User.joins(:agent)
                              .where(agents: { is_active: true })
                              .order(:email)
    end
  end


  def transaction_params
    params.require(:business_transaction).permit(
      :operation_type_id, :business_status_id, :start_date, :estimated_completion_date,
      :property_id, :offering_client_id, :acquiring_client_id,
      :co_ownership_type_id, :price, :commission_percentage, :notes,
      property_attributes: [:address, :property_type_id, :built_area_m2, :lot_area_m2, 
                           :bedrooms, :bathrooms, :street, :exterior_number, :interior_number, 
                           :postal_code, :neighborhood, :municipality, :state, :city, :country],
      co_owners_attributes: [:id, :client_id, :person_name, :percentage, :role, :deceased, 
                            :inheritance_case_notes, :_destroy]
    )
  end

end
