class Admin::BusinessTransactionCoOwnersController < Admin::BaseController
  before_action :set_transaction
  before_action :set_co_owner, only: [:show, :edit, :update, :destroy]

  def index
    @co_owners = policy_scope(@transaction.co_owners.includes(:client, :co_ownership_role))
    @total_percentage = @co_owners.active.sum(:percentage)
    @remaining_percentage = 100.0 - @total_percentage
  end

  def show
    authorize @co_owner
  end

  def new
    @co_owner = @transaction.co_owners.build
    authorize @co_owner
    load_form_data
  end

  def create
    @co_owner = @transaction.co_owners.build(co_owner_params)
    authorize @co_owner
    
    if @co_owner.save
      redirect_to admin_business_transaction_co_owners_path(@transaction), 
                  notice: 'Copropietario agregado exitosamente'
    else
      load_form_data
      render :new
    end
  end

  def edit
    authorize @co_owner
    load_form_data
  end

  def update
    authorize @co_owner

    if @co_owner.update(co_owner_params)
      redirect_to admin_business_transaction_co_owners_path(@transaction),
                  notice: 'Copropietario actualizado exitosamente'
    else
      load_form_data
      render :edit
    end
  end

  def destroy
    authorize @co_owner
    
    if @co_owner.destroy
      redirect_to admin_business_transaction_co_owners_path(@transaction),
                  notice: 'Copropietario eliminado exitosamente'
    else
      redirect_to admin_business_transaction_co_owners_path(@transaction),
                  alert: 'No se pudo eliminar el copropietario'
    end
  end

  private

  def set_transaction
    @transaction = BusinessTransaction.find(params[:business_transaction_id])
  end

  def set_co_owner
    @co_owner = @transaction.co_owners.find(params[:id])
  end

  def load_form_data
    @clients = Client.active.order(:name)
    # ✅ ROLES DINÁMICOS DESDE BD
    @roles = CoOwnershipRole.active.by_sort_order.pluck(:display_name, :name)
    @current_total = @transaction.co_owners.active.where.not(id: @co_owner&.id).sum(:percentage)
    @max_percentage = 100.0 - @current_total
  end

  def co_owner_params
    params.require(:business_transaction_co_owner)
          .permit(:client_id, :person_name, :percentage, :role, :deceased, 
                  :inheritance_case_notes, :active)
  end
end
