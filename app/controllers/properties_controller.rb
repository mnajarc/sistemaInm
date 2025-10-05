class PropertiesController < ApplicationController
  include ConfigurableController
  
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :load_catalog_options, only: [:new, :edit, :create, :update]
  
  def index
    @properties = policy_scope(Property)
    @properties = load_filtered_properties(@properties)
    @filter_options = build_filter_options
    @pagination_config = pagination_configuration
  end
  
  def show
    authorize @property
    @available_operations = @property.available_operations
    @operation_summaries = @property.operation_status_summary
  end
  
  def new
    @property = current_user.properties.build
    authorize @property
    initialize_property_defaults
  end
  
  def create
    @property = current_user.properties.build(property_params)
    authorize @property
    
    if @property.save
      redirect_to @property, notice: success_message('created')
    else
      load_catalog_options
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    authorize @property
  end
  
  def update
    authorize @property
    
    if @property.update(property_params)
      redirect_to @property, notice: success_message('updated')
    else
      load_catalog_options
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @property
    
    if @property.destroy
      redirect_to properties_path, notice: success_message('deleted')
    else
      redirect_to @property, alert: error_message('delete_failed')
    end
  end
  
  private
  
  def set_property
    @property = Property.find(params[:id])
  end
  
  def load_catalog_options
    @property_types = PropertyType.where(active: true).order(:sort_order)
    @co_ownership_types = CoOwnershipType.where(active: true).order(:sort_order)
  rescue => e
    Rails.logger.error "Error loading catalog options: #{e.message}"
    @property_types = []
    @co_ownership_types = []
  end
  
  def initialize_property_defaults
    # Valores por defecto configurables
    @property.assign_attributes(
      bedrooms: get_config('property.default_bedrooms', 1),
      bathrooms: get_config('property.default_bathrooms', 1),
      parking_spaces: get_config('property.default_parking_spaces', 0),
      furnished: get_config('property.default_furnished', false),
      pets_allowed: get_config('property.default_pets_allowed', true)
    )
  rescue => e
    Rails.logger.error "Error initializing property defaults: #{e.message}"
  end
  
  def load_filtered_properties(properties)
    # Filtros configurables
    properties = apply_type_filter(properties)
    properties = apply_price_filter(properties) 
    properties = apply_location_filter(properties)
    properties = apply_availability_filter(properties)
    
    # Ordenamiento configurable
    sort_option = params[:sort] || get_config('property.default_sort', 'created_at_desc')
    properties = apply_sorting(properties, sort_option)
    
    # Paginación con Kaminari
    per_page = get_config('property.items_per_page', 20)
    properties.page(params[:page]).per(per_page)
  rescue => e
    Rails.logger.error "Error in load_filtered_properties: #{e.message}"
    properties.limit(20)
  end
  
  def apply_type_filter(properties)
    return properties unless params[:property_type_id].present?
    properties.where(property_type_id: params[:property_type_id])
  end
  
  def apply_price_filter(properties)
    properties = properties.where('price >= ?', params[:min_price]) if params[:min_price].present?
    properties = properties.where('price <= ?', params[:max_price]) if params[:max_price].present?
    properties
  end
  
  def apply_location_filter(properties)
    return properties unless params[:city].present?
    properties.where('city ILIKE ?', "%#{params[:city]}%")
  end
  
  def apply_availability_filter(properties)
    return properties unless params[:available_for].present?
    
    case params[:available_for]
    when 'sale'
      properties.joins(:business_transactions)
                .where(business_transactions: { operation_type_id: OperationType.where(name: 'sale').select(:id) })
    when 'rent'
      properties.joins(:business_transactions)
                .where(business_transactions: { operation_type_id: OperationType.where(name: 'rent').select(:id) })
    else
      properties
    end
  rescue => e
    Rails.logger.error "Error applying availability filter: #{e.message}"
    properties
  end
  
  def apply_sorting(properties, sort_option)
    sort_configs = get_config('property.sort_options', {
      'price_asc' => 'price ASC',
      'price_desc' => 'price DESC', 
      'created_at_desc' => 'created_at DESC',
      'created_at_asc' => 'created_at ASC',
      'title_asc' => 'title ASC'
    })
    
    sort_sql = sort_configs[sort_option] || 'created_at DESC'
    properties.order(sort_sql)
  rescue => e
    Rails.logger.error "Error applying sorting: #{e.message}"
    properties.order(:created_at)
  end
  
  def build_filter_options
    {
      property_types: safe_pluck(PropertyType.where(active: true), :display_name, :id),
      cities: safe_pluck(Property.distinct, :city),
      price_ranges: price_range_options,
      availability_options: availability_options
    }
  rescue => e
    Rails.logger.error "Error building filter options: #{e.message}"
    { property_types: [], cities: [], price_ranges: [], availability_options: [] }
  end
  
  def safe_pluck(relation, *columns)
    relation.pluck(*columns).compact
  rescue => e
    Rails.logger.error "Error in safe_pluck: #{e.message}"
    []
  end
  
  def price_range_options
    ranges = get_config('property.price_ranges', [
      { 'label' => 'Hasta $100,000', 'max' => 100_000 },
      { 'label' => '$100,000 - $300,000', 'min' => 100_000, 'max' => 300_000 },
      { 'label' => '$300,000 - $500,000', 'min' => 300_000, 'max' => 500_000 },
      { 'label' => 'Más de $500,000', 'min' => 500_000 }
    ])
    
    ranges.map { |range| [range['label'], range] }
  rescue => e
    Rails.logger.error "Error loading price ranges: #{e.message}"
    []
  end
  
  def availability_options
    get_config('property.availability_filter_options', [
      ['Disponible para venta', 'sale'],
      ['Disponible para alquiler', 'rent'],
      ['Cualquier disponibilidad', '']
    ])
  rescue => e
    Rails.logger.error "Error loading availability options: #{e.message}"
    [['Cualquier disponibilidad', '']]
  end
  
  def pagination_configuration
    {
      per_page_options: get_config('property.per_page_options', [10, 20, 50, 100]),
      show_page_info: get_config('property.show_pagination_info', true),
      show_per_page_selector: get_config('property.show_per_page_selector', true)
    }
  rescue => e
    Rails.logger.error "Error loading pagination config: #{e.message}"
    { per_page_options: [20], show_page_info: true, show_per_page_selector: false }
  end
  
  def success_message(action)
    messages = get_config('messages.property_success', {
      'created' => 'Propiedad creada exitosamente.',
      'updated' => 'Propiedad actualizada exitosamente.',
      'deleted' => 'Propiedad eliminada exitosamente.'
    })
    
    messages[action] || 'Operación completada exitosamente.'
  end
  
  def error_message(type)
    messages = get_config('messages.property_errors', {
      'delete_failed' => 'No se pudo eliminar la propiedad.',
      'insufficient_permissions' => 'No tienes permisos para realizar esta acción.'
    })
    
    messages[type] || 'Ha ocurrido un error.'
  end
  
  def property_params
    # Parámetros permitidos configurables
    base_params = get_config('property.base_permitted_params', [
      :title, :description, :price, :address, :city, :state, :postal_code,
      :bedrooms, :bathrooms, :built_area_m2, :lot_area_m2, :year_built,
      :property_type_id, :parking_spaces, :furnished, :pets_allowed,
      :elevator, :balcony, :terrace, :garden, :pool, :security, :gym,
      :contact_phone, :contact_email, :available_from, :co_ownership_type_id,
      :co_owners_details
    ])
    
    role_specific_params = get_config("property.#{current_user.role.name}_permitted_params", [])
    
    allowed_params = base_params + role_specific_params
    params.require(:property).permit(allowed_params)
  rescue => e
    Rails.logger.error "Error getting property params: #{e.message}"
    params.require(:property).permit!
  end
end