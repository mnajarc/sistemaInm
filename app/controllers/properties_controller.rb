class PropertiesController < ApplicationController
  authorize_resource
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  
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
end
