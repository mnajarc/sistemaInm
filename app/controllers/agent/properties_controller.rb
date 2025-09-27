class Agent::PropertiesController < Agent::BaseController
  before_action :set_property, only: [:show, :edit, :update]

  def index
    @properties = policy_scope(Property)
                    .includes(:property_type, :co_ownership_type)
                    .order(created_at: :desc)
  end

  def show
    authorize @property
  end

  def edit
    authorize @property
    load_form_data
  end

  def update
    authorize @property
    
    if @property.update(property_params)
      redirect_to agent_property_path(@property), notice: 'Propiedad actualizada exitosamente'
    else
      load_form_data
      render :edit
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def load_form_data
    @property_types = PropertyType.active.order(:sort_order)
    @co_ownership_types = CoOwnershipType.active.order(:sort_order)
  end

  def property_params
    params.require(:property).permit(
      :title, :description, :price, :address, :city, :state, :postal_code,
      :bedrooms, :bathrooms, :built_area_m2, :lot_area_m2, :year_built,
      :property_type_id, :co_ownership_type_id, :parking_spaces, 
      :furnished, :pets_allowed, :elevator, :balcony, :terrace, 
      :garden, :pool, :security, :gym, :available_from,
      :contact_phone, :contact_email, :internal_notes
    )
  end
end
