class Admin::BusinessStatusesController < Admin::BaseController
  before_action :set_business_status, only: [:show, :edit, :update, :destroy]
  
  def index
    @business_statuses = policy_scope(BusinessStatus).order(:sort_order)
    authorize BusinessStatus
  end
  
  def show
    authorize @business_status
  end
  
  def new
    @business_status = BusinessStatus.new(active: true, sort_order: 10)
    authorize @business_status
  end
  
  def create
    @business_status = BusinessStatus.new(business_status_params)
    authorize @business_status
    
    if @business_status.save
      redirect_to admin_business_statuses_path, notice: 'Estado de negocio creado exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    authorize @business_status
  end
  
  def update
    authorize @business_status
    
    if @business_status.update(business_status_params)
      redirect_to admin_business_statuses_path, notice: 'Estado actualizado exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @business_status
    
    if @business_status.business_transactions.exists?
      redirect_to admin_business_statuses_path, 
                  alert: 'No se puede eliminar: existen transacciones con este estado'
    else
      @business_status.destroy
      redirect_to admin_business_statuses_path, notice: 'Estado eliminado exitosamente'
    end
  end
  
  private
  
  def set_business_status
    @business_status = BusinessStatus.find(params[:id])
  end
  
  def business_status_params
    params.require(:business_status).permit(:name, :display_name, :description, :color, :active, :sort_order)
  end
end

