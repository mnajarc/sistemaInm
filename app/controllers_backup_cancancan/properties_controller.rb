class PropertiesController < ApplicationController
  # authorize_resource
  # before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
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
      redirect_to @property, notice: 'Propiedad creada exitosamente'
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
      redirect_to @property, notice: 'Propiedad actualizada exitosamente'
    else
      render :edit
    end
  end
  
  def destroy
    @property = Property.find(params[:id])
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: 'Propiedad eliminada exitosamente'
  end
  
  private
  
  def property_params
    params.require(:property).permit(:title, :description, :price, :property_type_id, 
                                   :property_status_id, :operation_type_id, :address, 
                                   :city, :state, :postal_code, :bedrooms, :bathrooms, 
                                   :built_area_m2, :lot_area_m2, :year_built)
  end
=begin
end 
  def index
    @properties = Property.includes(:user).all
  end

  def show
  end

  def new
    @property = current_user.properties.build
  end

  def create
    @property = current_user.properties.build(property_params)
    
    if @property.save
      redirect_to @property, notice: 'Propiedad creada exitosamente.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: 'Propiedad actualizada exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_url, notice: 'Propiedad eliminada exitosamente.'
  end



  private

  def set_property
    @property = Property.find(params[:id])
    authorize! :read, @property

  end

  def property_params
    params.require(:property).permit(:title, :description, :price, :property_type, 
                                   :status, :address, :city, :state, :postal_code,
                                   :bedrooms, :bathrooms, :built_area_m2, 
                                   :lot_area_m2, :year_built)
  end
=end
end
