
# app/controllers/properties_controller.rb
class PropertiesController < BaseController  # ✅ Cambiar herencia
  def index
    @properties = policy_scope(Property)
    authorize Property
  end

  def show
    @property = Property.find(params[:id])
    authorize @property
  end

  def new
    @property = Property.new
    authorize @property
  end

  def create
    @property = current_user.properties.build(property_params)
    authorize @property

    if @property.save
      redirect_to @property, notice: "Propiedad creada exitosamente"
    else
      render :new
    end
  end

  def edit
    @property = Property.find(params[:id])
    authorize @property
  end

  def update
    @property = Property.find(params[:id])
    authorize @property

    if @property.update(property_params)
      redirect_to @property, notice: "Propiedad actualizada exitosamente"
    else
      render :edit
    end
  end

  def destroy
    @property = Property.find(params[:id])
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: "Propiedad eliminada exitosamente"
  end

  private

  def property_params
    params.require(:property).permit(:title, :description, :price,
                                  :property_type_id, # ✅ Solo este
                                  :address, :city, :state, :postal_code,
                                  :bedrooms, :bathrooms, :built_area_m2,
                                  :lot_area_m2, :year_built)
  end
end
