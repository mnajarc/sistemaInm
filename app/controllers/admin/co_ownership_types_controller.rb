class Admin::CoOwnershipTypesController < Admin::BaseController
  before_action :set_type, only: %i[show edit update destroy]

  def index
    @types = policy_scope(CoOwnershipType).order(:sort_order)
  end

  def show
    authorize @type
  end

  def new
    @type = CoOwnershipType.new
    authorize @type
  end

  def create
    @type = CoOwnershipType.new(type_params)
    authorize @type
    if @type.save
      redirect_to admin_co_ownership_types_path, notice: 'Tipo de copropiedad creado exitosamente'
    else
      render :new
    end
  end

  def edit
    authorize @type
  end

  def update
    authorize @type
    if @type.update(type_params)
      redirect_to admin_co_ownership_types_path, notice: 'Tipo de copropiedad actualizado exitosamente'
    else
      render :edit
    end
  end

  def destroy
    authorize @type
    @type.destroy
    redirect_to admin_co_ownership_types_path, notice: 'Tipo de copropiedad eliminado exitosamente'
  end

  private

  def set_type
    @type = CoOwnershipType.find(params[:id])
  end

  def type_params
    params.require(:co_ownership_type).permit(:name, :display_name, :description, :active, :sort_order)
  end
end
