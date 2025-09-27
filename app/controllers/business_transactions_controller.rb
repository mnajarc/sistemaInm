# BusinessTransactionsController COMPLETO - RESTAURADO

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
    
    # ✅ SIEMPRE crear al menos 1 copropietario por defecto
    @transaction.co_owners.build(percentage: 100.0, role: 'vendedor')
    
    load_form_data
  end

  def create
    @transaction = BusinessTransaction.new(transaction_params)
    authorize @transaction
    
    # ✅ LÓGICA DE ASIGNACIÓN POR ROL
    assign_agents_by_role
    
    if @transaction.save
      redirect_to @transaction, notice: "Transacción creada exitosamente y asignada a #{@transaction.current_agent.email}"
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @transaction
    
    if @transaction.co_owners.empty?
      @transaction.co_owners.build(percentage: 100.0, role: 'vendedor')
    end
    
    load_form_data
  end

  def update
    authorize @transaction
    
    # ✅ PERMITIR REASIGNACIÓN SOLO A ADMIN/SUPERADMIN
    if current_user.admin_or_above? && params[:business_transaction][:current_agent_id].present?
      reassign_agent
    end
    
    # ✅ PERMITIR ASIGNACIÓN DE SELLING_AGENT
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

  private

  def set_transaction
    @transaction = BusinessTransaction.find(params[:id])
  end

  # ✅ ASIGNACIÓN INTELIGENTE POR ROL - INCLUYE SELLING_AGENT
  def assign_agents_by_role
    case current_user.role.name
    when 'agent'
      # AGENTE: Solo puede asignarse a sí mismo
      @transaction.listing_agent = current_user
      @transaction.current_agent = current_user
      # selling_agent se queda nil hasta que se asigne
      
    when 'admin', 'superadmin'
      # ADMIN/SUPERADMIN: Puede asignar a cualquier agente
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
        # Si no especifica agente, asignar al primer agente disponible
        first_agent = User.joins(:agent).where(agents: { is_active: true }).first
        if first_agent
          @transaction.listing_agent = first_agent
          @transaction.current_agent = first_agent
        else
          @transaction.errors.add(:base, "No hay agentes activos disponibles para asignar")
          return false
        end
      end
      
      # ✅ ASIGNAR SELLING_AGENT SI SE ESPECIFICA
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
    
    # ✅ PROPIEDADES SEGÚN ROL
    @properties = if current_user.admin_or_above?
                    Property.includes(:property_type, :user).order(:title)
                  else
                    # Agentes solo ven sus propiedades
                    Property.where(user: current_user).includes(:property_type)
                  end
    
    @operation_types = OperationType.active.order(:sort_order)
    @business_statuses = BusinessStatus.active.order(:sort_order)
    @co_ownership_roles = CoOwnershipRole.active.order(:sort_order)
    
    # ✅ AGENTES DISPONIBLES (Solo para Admin/SuperAdmin)
    if current_user.admin_or_above?
      @available_agents = User.joins(:agent)
                              .where(agents: { is_active: true })
                              .order(:email)
    end
  end

  def transaction_params
    permitted_params = [
      :property_id, :operation_type_id, :business_status_id,
      :offering_client_id, :acquiring_client_id,
      :price, :commission_percentage, :start_date, :estimated_completion_date, :notes,
      co_owners_attributes: [
        :id, :client_id, :person_name, :percentage, :role, 
        :deceased, :inheritance_case_notes, :active, :_destroy
      ]
    ]
    
    # ✅ SOLO ADMIN/SUPERADMIN PUEDEN ESPECIFICAR AGENTES
    if current_user.admin_or_above?
      permitted_params += [:current_agent_id, :selling_agent_id]
    end
    
    params.require(:business_transaction).permit(permitted_params)
  end
end
    