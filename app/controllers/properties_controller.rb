# app/controllers/properties_controller.rb
class PropertiesController < ApplicationController
  include Pundit::Authorization  # ← AGREGAR ESTA LÍNEA

  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    @properties = policy_scope(Property)
                    .includes(:property_type, :user, :co_ownership_type)
                    .order(created_at: :desc)
                    .page(params[:page])
  end

  def show
    authorize @property
  end

  def new
    @property = Property.new
    authorize @property
    load_form_data
  end

  def create
    @property = Property.new(property_params)
    @property.user = current_user
    authorize @property

    if @property.save
      # ✅ Si es AJAX, retornar JSON
      if request.xhr? || request.format.json?
        render json: @property.to_json(only: [:id, :title, :price, :address]), status: :created
      else
        redirect_to @property, notice: 'Propiedad creada exitosamente'
      end
    else
      if request.xhr? || request.format.json?
        render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end
  end


  def edit
    authorize @property
    load_form_data
  end

  def update
    authorize @property

    if @property.update(property_params)
      redirect_to @property, notice: 'Propiedad actualizada exitosamente'
    else
      load_form_data
      render :edit
    end
  end

  def destroy
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: 'Propiedad eliminada exitosamente'
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def load_form_data
    @property_types = PropertyType.active.order(:sort_order)
    @co_ownership_types = CoOwnershipType.active.order(:sort_order)
    @agents = User.joins(:role).where(roles: { name: ['agent', 'admin', 'superadmin'] })
                  .where(active: true).order(:email) if can_assign_agents?
  end

  def can_assign_agents?
    current_user&.role&.name.in?(['admin', 'superadmin'])
  end

  def property_params
    permitted = [
      :title, :description, :price, :address, :city, :state, :postal_code,
      :bedrooms, :bathrooms, :built_area_m2, :lot_area_m2, :year_built,
      :property_type_id, :co_ownership_type_id, :parking_spaces,
      :furnished, :pets_allowed, :elevator, :balcony, :terrace,
      :garden, :pool, :security, :gym, :available_from,
      # ✅ AGREGAR ESTOS (ya existen en BD):
      :street, :exterior_number, :interior_number,
      :neighborhood, :municipality, :country,
      :land_use, :has_extensions, :co_owners_details,
      :latitude, :longitude,
      :contact_phone, :contact_email, :internal_notes, :published_at
    ]
    
    if current_user&.role&.level.to_i <= 30
      permitted += [:contact_phone, :contact_email, :internal_notes]
    end
    
    if current_user&.role&.level.to_i <= 10
      permitted += [:user_id]
    end
  
    params.require(:property).permit(permitted)
  end
end
  