class Admin::PropertyTypesController < Admin::BaseController
  before_action :set_property_type, only: [ :show, :edit, :update, :destroy ]

  def index
    @property_types = policy_scope(PropertyType).order(:sort_order)
    authorize PropertyType
  end

  def show
    authorize @property_type
  end

  def new
    @property_type = PropertyType.new(active: true, sort_order: 10)
    authorize @property_type
  end

  def create
    @property_type = PropertyType.new(property_type_params)
    authorize @property_type

    if @property_type.save
      redirect_to admin_property_types_path, notice: "Tipo de propiedad creado exitosamente"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @property_type
  end

  def update
    authorize @property_type

    if @property_type.update(property_type_params)
      redirect_to admin_property_types_path, notice: "Tipo actualizado exitosamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @property_type

    if @property_type.properties.exists?
      redirect_to admin_property_types_path,
                  alert: "No se puede eliminar: existen propiedades con este tipo"
    else
      @property_type.destroy
      redirect_to admin_property_types_path, notice: "Tipo eliminado exitosamente"
    end
  end

  private

  def set_property_type
    @property_type = PropertyType.find(params[:id])
  end

  def property_type_params
    params.require(:property_type).permit(:name, :display_name, :description, :active, :sort_order)
  end
end
