class Admin::CoOwnershipTypesController < Admin::BaseController
  before_action :set_co_ownership_type, only: [:show, :edit, :update, :destroy]
  
  def index
    @co_ownership_types = policy_scope(CoOwnershipType).order(:sort_order)
    authorize CoOwnershipType
  end
  
  def show
    authorize @co_ownership_type
  end
  
  def new
    @co_ownership_type = CoOwnershipType.new(active: true, sort_order: 10)
    authorize @co_ownership_type
  end
  
  def create
    @co_ownership_type = CoOwnershipType.new(co_ownership_type_params)
    authorize @co_ownership_type
    
    if @co_ownership_type.save
      redirect_to admin_co_ownership_types_path, notice: 'Tipo de copropiedad creado exitosamente'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    authorize @co_ownership_type
  end
  
  def update
    authorize @co_ownership_type
    
    if @co_ownership_type.update(co_ownership_type_params)
      redirect_to admin_co_ownership_types_path, notice: 'Tipo actualizado exitosamente'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @co_ownership_type
    
    if @co_ownership_type.properties.exists?
      redirect_to admin_co_ownership_types_path, 
                  alert: 'No se puede eliminar: existen propiedades con este tipo de copropiedad'
    else
      @co_ownership_type.destroy
      redirect_to admin_co_ownership_types_path, notice: 'Tipo eliminado exitosamente'
    end
  end
  
  private
  
  def set_co_ownership_type
    @co_ownership_type = CoOwnershipType.find(params[:id])
  end
  
  def co_ownership_type_params
    params.require(:co_ownership_type).permit(:name, :display_name, :description, :active, :sort_order)
  end
end
