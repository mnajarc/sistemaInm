class Admin::OperationTypesController < Admin::BaseController
  before_action :set_operation_type, only: [ :show, :edit, :update, :destroy ]

  def index
    @operation_types = policy_scope(OperationType).order(:sort_order)
    authorize OperationType
  end

  def show
    authorize @operation_type
  end

  def new
    @operation_type = OperationType.new(active: true, sort_order: 10)
    authorize @operation_type
  end

  def create
    @operation_type = OperationType.new(operation_type_params)
    authorize @operation_type

    if @operation_type.save
      redirect_to admin_operation_types_path, notice: "Tipo de operación creado exitosamente"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @operation_type
  end

  def update
    authorize @operation_type

    if @operation_type.update(operation_type_params)
      redirect_to admin_operation_types_path, notice: "Tipo actualizado exitosamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @operation_type

    if @operation_type.business_transactions.exists?
      redirect_to admin_operation_types_path,
                  alert: "No se puede eliminar: existen transacciones con este tipo de operación"
    else
      @operation_type.destroy
      redirect_to admin_operation_types_path, notice: "Tipo eliminado exitosamente"
    end
  end

  private

  def set_operation_type
    @operation_type = OperationType.find(params[:id])
  end

  def operation_type_params
    params.require(:operation_type).permit(:name, :display_name, :description, :active, :sort_order)
  end
end
