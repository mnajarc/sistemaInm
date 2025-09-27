class Admin::PropertiesController < Admin::BaseController
    before_action :set_property, only: [:show, :edit, :update, :destroy]
  
    def index
      @properties = policy_scope(Property).includes(:property_type, :user, :co_ownership_type).order(created_at: :desc).page(params[:page])
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
      @property.user = current_user unless params[:property][:user_id].present?
      authorize @property
      
      if @property.save
        redirect_to admin_property_path(@property), notice: 'Propiedad creada exitosamente'
      else
        load_form_data
        render :new
      end
    end
  
    def edit
      authorize @property
      load_form_data
    end
  
    def update
      authorize @property
      
      if @property.update(property_params)
        redirect_to admin_property_path(@property), notice: 'Propiedad actualizada exitosamente'
      else
        load_form_data
        render :edit
      end
    end
  
    def destroy
      authorize @property
      @property.destroy
      redirect_to admin_properties_path, notice: 'Propiedad eliminada exitosamente'
    end
  
    private
  
    def set_property
      @property = Property.find(params[:id])
    end
    
    def load_form_data
      @property_types = PropertyType.active.order(:sort_order)
      @co_ownership_types = CoOwnershipType.active.order(:sort_order)
      @agents = User.joins(:agent).where(agents: { is_active: true }).order(:email)
    end

    def property_params
      params.require(:property).permit(:title, :description, :price, :address, :city, :state, 
                                     :postal_code, :bedrooms, :bathrooms, :built_area_m2, 
                                     :lot_area_m2, :year_built, :property_type_id, 
                                     :co_ownership_type_id, :parking_spaces, :furnished, 
                                     :pets_allowed, :elevator, :balcony, :terrace, :garden, 
                                     :pool, :security, :gym, :available_from)
    end
  end
  