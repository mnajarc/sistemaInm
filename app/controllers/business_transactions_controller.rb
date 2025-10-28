class BusinessTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy transfer_agent export_documents]

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
    @transaction.build_property
    @transaction.business_transaction_co_owners.build(percentage: 100.0, role: 'propietario')
    load_form_data
  end

  def create
    @transaction = BusinessTransaction.new(transaction_params)
    
    authorize @transaction
    assign_agents_by_role if respond_to?(:assign_agents_by_role, true)

    # ✅ AUTO-AGREGAR OFFERING CLIENT COMO COPROPIETARIO SI ESTÁ VACÍO
    if @transaction.business_transaction_co_owners.empty? && @transaction.offering_client_id.present?
      @transaction.business_transaction_co_owners.build(
        client_id: @transaction.offering_client_id,
        person_name: @transaction.offering_client&.display_name,
        percentage: 100,
        role: 'vendedor'
      )
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
    if @transaction.business_transaction_co_owners.empty?
      @transaction.business_transaction_co_owners.build(percentage: 100.0, role: 'propietario')
    end
    load_form_data
  end

  def update
    authorize @transaction

    if current_user.admin_or_above? && params[:business_transaction][:current_agent_id].present?
      reassign_agent
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
    service = TransactionExportService.new(@transaction, base_path: export_base_path)
    result = service.export

    if result[:success]
      redirect_to @transaction, notice: "📂 #{result[:message]}"
    else
      redirect_to @transaction, alert: "❌ #{result[:message]}"
    end
  end

  private

  def export_base_path
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
      first_agent = User.joins(:agent).where(agents: { is_active: true }).first
      @transaction.listing_agent = first_agent if first_agent
      @transaction.current_agent = first_agent if first_agent
    end
  end

  def reassign_agent
    if params[:business_transaction][:current_agent_id].present?
      new_agent = User.find(params[:business_transaction][:current_agent_id])
      @transaction.current_agent = new_agent if new_agent.agent?
    end
  end

  def load_form_data
    @clients = Client.active.order(:name)
    @properties = Property.includes(:property_type, :user).order(:address)
    @operation_types = OperationType.active.order(:sort_order)
    @business_statuses = BusinessStatus.active.order(:sort_order)
    @property_types = PropertyType.active.order(:sort_order)
    @co_ownership_types = CoOwnershipType.active.order(:sort_order)
    @co_ownership_roles = CoOwnershipRole.active.order(:sort_order)
    @roles = @co_ownership_roles.pluck(:display_name, :name)
  end

  def transaction_params
    params.require(:business_transaction).permit(
      :operation_type_id, :business_status_id, :start_date, :property_id,
      :offering_client_id, :acquiring_client_id, :co_ownership_type_id,
      :price, :commission_percentage, :notes,
      property_attributes: [
        :address, :property_type_id, :built_area_m2, :lot_area_m2,
        :bedrooms, :bathrooms, :street, :exterior_number, :interior_number,
        :postal_code, :neighborhood, :municipality, :state, :city, :country
      ],
      business_transaction_co_owners_attributes: [
        :id, :client_id, :person_name, :percentage, :role, :deceased,
        :inheritance_case_notes, :_destroy
      ]
    )
  end
end
