class BusinessTransactionsController < ApplicationController
  before_action :set_business_transaction, only: [:show, :edit, :update, :destroy, :transfer_agent]
  before_action :load_form_options, only: [:new, :edit, :create, :update]
  before_action :ensure_agent_or_above!, except: [:index, :show]
  
  def index
    @transactions = load_filtered_transactions
    @filter_stats = calculate_filter_statistics
  end
  
  def show
    @co_owners = @transaction.co_owners.active.includes(:client)
    @agent_transfers = @transaction.agent_transfers.includes(:from_agent, :to_agent, :transferred_by)
  end
  
  def new
    @transaction = BusinessTransaction.new
    @property = Property.find(params[:property_id]) if params[:property_id]
    initialize_transaction_defaults
  end
  
  def create
    @transaction = BusinessTransaction.new(transaction_params)
    
    if @transaction.save
      redirect_to @transaction, notice: success_message('transaction_created')
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end
  
  def transfer_agent
    new_agent = User.find(params[:new_agent_id])
    reason = params[:reason]
    
    if @transaction.transfer_to_agent!(new_agent, reason, current_user)
      redirect_to @transaction, notice: success_message('agent_transferred')
    else
      redirect_to @transaction, alert: error_message('transfer_failed')
    end
  end
  
  private
  
  def ensure_agent_or_above!
    agent_level = get_config('roles.agent_max_level', 20)
    authorize_minimum_level!(agent_level)
  end
  
  def load_filtered_transactions
    transactions = BusinessTransaction.includes(:property, :business_status, :operation_type, :current_agent)
    
    # Filtros según rol y configuración
    transactions = apply_role_restrictions(transactions)
    transactions = apply_status_filter(transactions)
    transactions = apply_operation_filter(transactions)
    transactions = apply_agent_filter(transactions)
    transactions = apply_date_filter(transactions)
    
    # Ordenamiento y paginación
    sort_option = params[:sort] || get_config('transactions.default_sort', 'start_date_desc')
    transactions = apply_transaction_sorting(transactions, sort_option)
    
    per_page = get_config('transactions.items_per_page', 15)
    transactions.page(params[:page]).per(per_page)
  end
  
  def apply_role_restrictions(transactions)
    case current_user.role.name
    when *get_config('roles.superadmin_names', ['superadmin'])
      transactions # Ve todas
    when *get_config('roles.admin_names', ['admin'])
      transactions # Ve todas
    when *get_config('roles.agent_names', ['agent'])
      transactions.by_current_agent(current_user)
    else
      transactions.none # Clientes no ven transacciones aquí
    end
  end
  
  def initialize_transaction_defaults
    defaults = get_config('transactions.defaults', {})
    
    @transaction.assign_attributes(
      start_date: defaults['start_date'] || Date.current,
      commission_percentage: defaults['commission_percentage'] || 0.0,
      listing_agent: current_user,
      current_agent: current_user
    )
    
    if @property
      @transaction.property = @property
      # Configurar valores por defecto según tipo de propiedad
      if @property.property_type
        type_defaults = @property.property_type.metadata_for('transaction_defaults', {})
        @transaction.assign_attributes(type_defaults) if type_defaults.any?
      end
    end
  end
  
  def load_form_options
    @properties = Property.includes(:property_type)
    @operation_types = OperationType.for_display
    @business_statuses = accessible_business_statuses
    @clients = Client.active.order(:name)
    @agents = User.joins(:role).where(roles: { name: get_config('roles.agent_names', ['agent']) }).active
  end
  
  def calculate_filter_statistics
    base_query = apply_role_restrictions(BusinessTransaction.all)
    
    {
      total: base_query.count,
      active: base_query.active.count,
      completed: base_query.completed.count,
      in_progress: base_query.in_progress.count,
      by_operation: base_query.joins(:operation_type).group('operation_types.display_name').count,
      by_status: base_query.joins(:business_status).group('business_statuses.display_name').count
    }
  end
  
  def transaction_params
    base_params = get_config('transactions.base_permitted_params', [
      :property_id, :operation_type_id, :business_status_id,
      :offering_client_id, :acquiring_client_id, :start_date,
      :estimated_completion_date, :price, :commission_percentage,
      :notes, :terms_and_conditions, :listing_agent_id, :current_agent_id,
      co_owners_attributes: [:id, :client_id, :person_name, :percentage, :role, :deceased, :inheritance_case_notes, :active, :_destroy]
    ])
    
    params.require(:business_transaction).permit(base_params)
  end
end