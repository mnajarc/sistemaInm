# app/controllers/initial_contact_forms_controller.rb
class InitialContactFormsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_form, only: [:show, :edit, :update, :destroy, :convert_to_transaction, :suggest_acquisition_method, 
                                    :edit_property_modal, :update_property_from_modal,
                                    :edit_client_modal, :update_client_from_modal,
                                    :edit_co_owners_modal, :create_co_owner]
  before_action :authorize_form, except: [:index, :new, :create]

  def index
    # Base query con eager loading
    base_scope = InitialContactForm
      .includes(
        :agent,
        :client,
        :property,
        :business_transaction,
        :property_acquisition_method,
        :operation_type,
        :contract_signer_type
      )
    
    # Filtro por rol
    if current_user.superadmin? || current_user.admin?
      @forms = base_scope.all
    elsif current_user.agent.present?
      @forms = base_scope.where(agent_id: current_user.agent.id)
    else
      redirect_to root_path, alert: '⚠️ No tienes permisos para ver formularios.'
      return
    end
    
    # Filtro por agente (admin/superadmin)
    if params[:agent_id].present? && (current_user.superadmin? || current_user.admin?)
      @forms = @forms.where(agent_id: params[:agent_id])
    end
    
    # Filtro por estado
    if params[:status].present?
      @forms = @forms.where(status: params[:status])
    end
    
    # Filtro por método de adquisición
    if params[:acquisition_method_id].present?
      @forms = @forms.where(property_acquisition_method_id: params[:acquisition_method_id])
    end
    
    # Filtro por tipo de operación
    if params[:operation_type_id].present?
      @forms = @forms.where(operation_type_id: params[:operation_type_id])
    end
    
    # ═══════════════════════════════════════════════════════════
    # Filtro por periodo - CORREGIDO
    # ═══════════════════════════════════════════════════════════
    if params[:period].present?
      @forms = @forms.where('created_at >= ?', case params[:period]
      when 'today'
        Time.current.beginning_of_day
      when 'week'
        Time.current.beginning_of_week
      when 'month'
        Time.current.beginning_of_month
      when 'quarter'
        3.months.ago
      when 'year'
        Time.current.beginning_of_year
      else
        0.years.ago
      end)
    end
    
    # Búsqueda por nombre de propietario
    if params[:owner_name].present?
      @forms = @forms.where(
        "general_conditions->>'owner_or_representative_name' ILIKE ?", 
        "%#{params[:owner_name]}%"
      )
    end
    
    # Búsqueda por identificador
    if params[:property_identifier].present?
      @forms = @forms.where(
        "opportunity_identifier ILIKE ?", 
        "%#{params[:property_identifier]}%"
      )
    end
    
    # Ordenamiento y paginación
    @forms = @forms.order(created_at: :desc).page(params[:page]).per(20)
    
    # Datos para dropdowns (solo si es admin/superadmin)
    if current_user.superadmin? || current_user.admin?
      @agents = Agent.includes(:user).order('users.name')
    end
    
    @acquisition_methods = PropertyAcquisitionMethod.order(:name)
    @operation_types = OperationType.order(:name)
  end

  def new
    @initial_contact_form = InitialContactForm.new(agent: current_user.agent)
    load_form_data
  end
  
  def create
    @form = InitialContactForm.new(form_params)
    @form.agent ||= current_user.agent
    
    unless @form.agent.present?
      redirect_to root_path, alert: '❌ No tienes un agente asignado. Contacta al administrador.'
      return
    end    
    
    # Detectar qué botón se presionó
    @form.status = case params.keys
                   when -> k { k.include?('save_draft') } then :draft
                   when -> k { k.include?('complete') } then :completed
                   else :draft
                   end
    
    if @form.save
      notice_message = @form.auto_generated_identifier ? 
                        '✅ Formulario creado. ⚠️ Identificador generado automáticamente.' :
                        '✅ Formulario creado exitosamente'
      redirect_to @form, notice: notice_message
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @initial_contact_form = InitialContactForm.find(params[:id])
    load_form_data
  end

def update
  @initial_contact_form = InitialContactForm.find(params[:id])
  
  # 🔧 AUTO-VINCULAR PROPIEDAD SI NO TIENE
  if @initial_contact_form.property_id.blank? && @initial_contact_form.property_info.present?
    street = @initial_contact_form.property_info['street']
    ext_num = @initial_contact_form.property_info['exterior_number']
    int_num = @initial_contact_form.property_info['interior_number']
    neighborhood = @initial_contact_form.property_info['neighborhood']
    municipality = @initial_contact_form.property_info['municipality']
    state = @initial_contact_form.property_info['state']
    
    # Buscar propiedad por ubicación
    property = Property.find_by_location(street, ext_num, int_num, neighborhood, municipality, state)
    
    if property.present?
      @initial_contact_form.property_id = property.id
      Rails.logger.info "✓ Propiedad vinculada automáticamente: #{property.property_id}"
    else
      Rails.logger.warn "⚠ No se encontró propiedad para: #{street} #{ext_num} #{int_num}"
    end
  end
  
  # 🔘 DETECTAR QUÉ BOTÓN SE PRESIONÓ
  @initial_contact_form.assign_attributes(initial_contact_form_params)
  @initial_contact_form.status = case
                                  when params[:save_draft].present? then :draft
                                  when params[:complete].present? then :completed
                                  else @initial_contact_form.status
                                  end
  
  # 💾 GUARDAR
  if @initial_contact_form.save
    notice_message = @initial_contact_form.auto_generated_identifier ? 
                      '✅ Formulario actualizado. ⚠️ Identificador generado automáticamente.' :
                      '✅ Formulario actualizado exitosamente'
    redirect_to @initial_contact_form, notice: notice_message
  else
    load_form_data
    render :edit, status: :unprocessable_entity
  end
end



  def destroy
    @form.destroy
    redirect_to initial_contact_forms_url, notice: '✅ Formulario eliminado'
  end
  
  def convert_to_transaction
    if @form.convert_to_transaction!
      redirect_to business_transaction_path(@form.business_transaction), 
                  notice: '✅ Convertido a Transacción de Negocio'
    else
      redirect_to @form, alert: '❌ Error al convertir: ' + @form.errors.full_messages.join(', ')
    end
  end
  
  def suggest_acquisition_method
    suggestion = AcquisitionMethodSuggestion.create!(
      user: current_user,
      initial_contact_form: @form,
      suggested_name: params[:suggested_name],
      legal_basis: params[:legal_basis]
    )
    
    render json: { status: 'success', suggestion_id: suggestion.id }
  rescue StandardError => e
    render json: { status: 'error', message: e.message }, status: :unprocessable_entity
  end

  # ═══════════════════════════════════════════════════════════
  # MODALES - MÉTODOS PÚBLICOS
  # ═══════════════════════════════════════════════════════════
  
  def edit_property_modal
    @form_id = params[:id]
    respond_to do |format|
      format.turbo_stream
      format.html { render :edit_property_modal }
    end
  end
  
  def update_property_from_modal
    # Actualizar property_info
    @form.property_info = {
      'street' => params.dig(:property_info, :street),
      'exterior_number' => params.dig(:property_info, :exterior_number),
      'interior_number' => params.dig(:property_info, :interior_number),
      'neighborhood' => params.dig(:property_info, :neighborhood),
      'municipality' => params.dig(:property_info, :municipality),
      'city' => params.dig(:property_info, :city),
      'postal_code' => params.dig(:property_info, :postal_code),
      'country' => 'México'
    }
    
    # Actualizar acquisition_details
    @form.acquisition_details = (@form.acquisition_details || {}).merge({
      'state' => params.dig(:acquisition_details, :state),
      'land_use' => params.dig(:acquisition_details, :land_use)
    })
    
    if @form.save
      redirect_to @form, notice: "✅ Datos de propiedad actualizados"
    else
      render :edit_property_modal, status: :unprocessable_entity
    end
  end
  
  def edit_client_modal
    @form_id = params[:id]
    respond_to do |format|
      format.turbo_stream
      format.html { render :edit_client_modal }
    end
  end
  
  def update_client_from_modal
    # Actualizar general_conditions
    @form.general_conditions = {
      'owner_or_representative_name' => params.dig(:general_conditions, :owner_or_representative_name),
      'owner_phone' => params.dig(:general_conditions, :owner_phone),
      'owner_email' => params.dig(:general_conditions, :owner_email),
      'civil_status' => params.dig(:general_conditions, :civil_status),
      'marriage_regime_id' => params.dig(:general_conditions, :marriage_regime_id),
      'notes' => params.dig(:general_conditions, :notes)
    }
    
    if @form.save
      redirect_to @form, notice: "✅ Datos de cliente actualizados"
    else
      render :edit_client_modal, status: :unprocessable_entity
    end
  end
  
  def edit_co_owners_modal
    @form_id = params[:id]
    @co_owners_count = @form.acquisition_details&.dig('co_owners_count')&.to_i || 1
    @co_ownership_links = @form.business_transaction&.co_ownership_links || []
    
    respond_to do |format|
      format.turbo_stream
      format.html { render :edit_co_owners_modal }
    end
  end
  
  def create_co_owner
    # Validar entrada
    unless params[:co_owner_name].present? && params[:co_owner_email].present?
      return render json: { 
        errors: { base: 'Nombre y email del copropietario son requeridos' } 
      }, status: :unprocessable_entity
    end
    
    # Crear o encontrar cliente copropietario
    co_owner = Client.find_or_create_by(
      email: params[:co_owner_email]
    ) do |client|
      client.name = params[:co_owner_name]
      client.phone = params[:co_owner_phone]
      client.address = params[:co_owner_address]
      client.city = params[:co_owner_city]
      client.state = params[:co_owner_state]
    end
    
    if co_owner.save
      # Crear vínculo de copropiedad
      link = CoOwnershipLink.new(
        primary_client: @form.client,
        co_owner_client: co_owner,
        initial_contact_form: @form,
        ownership_percentage: params[:ownership_percentage],
        relationship_type: params[:relationship_type],
        notes: params[:notes]
      )
      
      if link.save
        render json: { 
          id: link.id, 
          opportunity_id: link.co_owner_opportunity_id,
          status: 'success'
        }
      else
        render json: { 
          errors: link.errors.full_messages 
        }, status: :unprocessable_entity
      end
    else
      render json: { 
        errors: co_owner.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  private

  def set_form
    @form = InitialContactForm.find(params[:id])
  end
  
  def authorize_form
    return if current_user.superadmin? || current_user.admin?
    
    unless @form.agent.user == current_user
      redirect_to root_path, alert: '❌ No tienes permiso para acceder'
    end
  end

  def load_form_data
    @acquisition_methods = PropertyAcquisitionMethod.active.order(:name)
    @contract_signers = ContractSignerType.active.order(:name)
    @marriage_regimes = MarriageRegime.active.order(:name)
    @operation_types = OperationType.active.order(:sort_order)
    
    # JSON seguro - escapar correctamente
    @acquisition_method_codes = JSON.generate(
      PropertyAcquisitionMethod.active.pluck(:id, :code).to_h
    )
  end

  def form_params
    params.require(:initial_contact_form).permit(
      :agent_id,
      :property_acquisition_method_id,
      :contract_signer_type_id,
      :operation_type_id,
      :client_id,
      :property_id,
      :status,
      :agent_notes,
      :form_source,
      :acquisition_clarification,
      :opportunity_identifier,
      
      general_conditions: [
        :owner_or_representative_name,
        :owner_phone,
        :owner_email,
        :owner_address,
        :domicile_type,
        :civil_status,
        :marriage_regime_id,
        :notes
      ],
      
      acquisition_details: [
        :co_owners_count,
        :has_co_owners,
        :state,
        :land_use,
        :has_relationship,
        :relationship_type,
        :acquired_pre_2014,
        :heirs_count,
        :all_living,
        :deceased_count,
        :all_married,
        :single_heirs_count,
        :deceased_civil_status,
        :inheritance_from,
        :inheritance_from_other,
        :parents_were_married,
        :parents_marriage_regime,
        :has_testamentary_succession,
        :succession_planned_date,
        :succession_authority,
        :succession_type,
        :has_judicial_sentence,
        :has_notarial_deed,
        :document_type,
        :donor_name,
        :donor_relationship,
        :donor_relationship_other,
        :beneficiaries_count
      ],
      
      property_info: [
        :address,
        :asking_price,
        :estimated_price,
        :bedrooms,
        :bathrooms,
        :built_area_m2,
        :lot_area_m2,
        :acquisition_date,
        :property_use,
        :has_improvements,
        :mortgage_bank,
        :street,
        :exterior_number,
        :interior_number,
        :neighborhood,
        :postal_code,
        :municipality,
        :city,
        :country
      ],
      
      current_status: [
        :has_active_mortgage,
        :mortgage_balance,
        :monthly_payment,
        :mortgage_payments_current,
        :in_collection_agency,
        :mortgage_notes,
        :has_extensions,
        :extensions_reported,
        :extensions_notes,
        :has_additions,
        :additions_registered,
        :additions_notes,
        :has_renovations,
        :knows_renovation_cost,
        :renovation_cost,
        :renovation_notes,
        :is_in_condominium,
        :condominium_regime,
        :has_condominium_rules,
        :has_maintenance_clearance,
        :has_rental_units,
        :rental_units_count,
        :apartment_units_count,
        :apartments_natural_light,
        :apartments_access,
        :apartments_have_kitchen,
        :apartments_finish_type,
        :commercial_units_count,
        :commercial_access,
        :commercial_shutters_count,
        :commercial_modifiable,
        :rental_units_notes
      ],
      
      tax_exemption: [
        :first_home_sale,
        :lived_last_5_years,
        :ine_matches_deed,
        :previous_sales_last_3_years,
        :previous_sale_date,
        :estimated_capital_gain,
        :qualifies_for_exemption
      ],
      
      promotion_preferences: [
        :allows_signage,
        :allows_flyers_with_address,
        :allows_open_house,
        :preferred_contact_method,
        :contact_hours,
        :special_instructions,
        signage_types: []
      ]
    )
  end
end
