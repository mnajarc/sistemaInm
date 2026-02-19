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
    load_form_data
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
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_form_data
    authorize @transaction
    if @transaction.business_transaction_co_owners.empty?
      @transaction.business_transaction_co_owners.build(percentage: 100.0, role: 'propietario')
    end
    load_form_data
  end

  def update
    normalize_coowner_params
    authorize @transaction

    # 🔥 LOGGING PARA DEBUG (AGREGAR ESTO)
    Rails.logger.info "🔥 PARAMS RECIBIDOS EN UPDATE:"
    Rails.logger.info params[:business_transaction].inspect
    
    if params[:business_transaction][:business_transaction_co_owners_attributes].present?
      Rails.logger.info "🔥 CO-OWNERS ATTRIBUTES:"
      params[:business_transaction][:business_transaction_co_owners_attributes].each do |key, attrs|
        Rails.logger.info "   [#{key}] => #{attrs.inspect}"
      end
    end

    if current_user.admin_or_above? && params[:business_transaction][:current_agent_id].present?
      reassign_agent
    end

    if @transaction.update(transaction_params)
      # 🔥 LOGGING DESPUÉS DE SAVE (AGREGAR ESTO)
      Rails.logger.info "✅ TRANSACCIÓN ACTUALIZADA"
      Rails.logger.info "   Co-owners count: #{@transaction.business_transaction_co_owners.count}"
      Rails.logger.info "   Co-owners IDs: #{@transaction.business_transaction_co_owners.pluck(:id)}"
      
      redirect_to @transaction, notice: "Transacción actualizada exitosamente"
    else
      # 🔥 LOGGING DE ERRORES (AGREGAR ESTO)
      Rails.logger.error "❌ ERROR AL ACTUALIZAR TRANSACCIÓN:"
      Rails.logger.error "   Transaction errors: #{@transaction.errors.full_messages}"
      
      # Mostrar errores de nested co_owners
      @transaction.business_transaction_co_owners.each_with_index do |co, idx|
        if co.errors.any?
          Rails.logger.error "   Co-owner [#{idx}] errors: #{co.errors.full_messages}"
        end
      end
      
      load_form_data
      render :edit, status: :unprocessable_content
    end
  end

  
  def update_anterior
    authorize @transaction

    if current_user.admin_or_above? && params[:business_transaction][:current_agent_id].present?
      reassign_agent
    end

    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: "Transacción actualizada exitosamente"
    else
      load_form_data
      render :edit, status: :unprocessable_content
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

  def normalize_coowner_params
    return unless params[:business_transaction][:business_transaction_co_owners_attributes]
    
    co_owners = params[:business_transaction][:business_transaction_co_owners_attributes]
    
    # Si existe la clave "NEW_RECORD", reindexarla
    if co_owners.key?("NEW_RECORD")
      new_record_data = co_owners.delete("NEW_RECORD")
      
      # Encontrar el índice más alto y sumar 1
      max_index = co_owners.keys.map(&:to_i).max || 0
      new_index = max_index + 1
      
      co_owners[new_index.to_s] = new_record_data
      
      Rails.logger.info "🔧 Normalizado NEW_RECORD → índice #{new_index}"
      Rails.logger.info "   Data: #{new_record_data.inspect}"
    end
  end

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
    @clients = Client.active.order(:full_name)
    @properties = Property.includes(:property_type, :user).order(:address)
    @operation_types = OperationType.active.order(:sort_order)
    @business_statuses = BusinessStatus.active.order(:sort_order)
    @property_types = PropertyType.active.order(:sort_order)
    @co_ownership_types = CoOwnershipType.active.order(:sort_order)
    @co_ownership_roles = CoOwnershipRole.active.order(:sort_order)
    @roles = @co_ownership_roles.pluck(:display_name, :name)
    @countries = Country.ordered
  end

  def transaction_params
    params.require(:business_transaction).permit(
      :operation_type_id, :business_status_id, :start_date, :property_id,
      :offering_client_id, :acquiring_client_id, :co_ownership_type_id,
      :price, :market_analysis_price, :suggested_price,
      :commission_percentage, :notes, :transaction_scenario_id,
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
