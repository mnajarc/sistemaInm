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
  @initial_contact_form = InitialContactForm.new(form_params)
  @initial_contact_form.agent = current_user.agent unless @initial_contact_form.agent.present?

  unless @initial_contact_form.agent.present?
    redirect_to root_path, alert: "No tienes un agente asignado. Contacta al administrador."
    return
  end

  # Detectar qué botón se presionó
  @initial_contact_form.status = case
                                   when params[:save_draft].present? then :draft
                                   when params[:complete].present? then :completed
                                   else :draft
                                   end


  # 🔴 DEBUG: Ver qué está pasando
  puts "=" * 80
  puts "🔍 DEBUG: Initial Contact Form Data"
  puts "=" * 80
  puts "general_conditions: #{@initial_contact_form.general_conditions.inspect}"
  puts "property_info: #{@initial_contact_form.property_info.inspect}"
  puts "acquisition_details: #{@initial_contact_form.acquisition_details.inspect}"
  puts "=" * 80



  if @initial_contact_form.save
    notice_message = @initial_contact_form.auto_generated_identifier ? 
                     "✅ Formulario creado. Identificador: #{@initial_contact_form.opportunity_identifier}" :
                     "✅ Formulario creado exitosamente"
    
    redirect_to @initial_contact_form, notice: notice_message
  else

    # 🔴 DEBUG: Ver errores
    puts "=" * 80
    puts "❌ ERRORES DE VALIDACIÓN:"
    puts @initial_contact_form.errors.full_messages.inspect
    puts "=" * 80


    # ✅ AQUÍ: Pasar la variable de instancia a la vista
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
    @initial_contact_form.assign_attributes(form_params)
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
  @form = InitialContactForm.find(params[:id])
  
  begin
    ActiveRecord::Base.transaction do
      # ========================================
      # 1. CREAR O ACTUALIZAR CLIENTE
      # ========================================
      @client = Client.from_initial_contact_form(@form)
      
      unless @client.save
        raise ActiveRecord::RecordInvalid, @client
      end

      @form.update!(client_id: @client.id)

      # ========================================
      # 2. USAR EL MÉTODO DEL MODELO (COMPLETO)
      # ========================================
      @transaction = @form.create_business_transaction!(@client, @form.property)

      # ========================================
      # 3. ACTUALIZAR ESTADO DEL FORMULARIO
      # ========================================
      @form.update!(
        business_transaction_id: @transaction.id,
        status: :converted,
        converted_at: Time.current
      )

      redirect_to business_transaction_path(@transaction), 
                  notice: '✅ Convertido a Transacción de Negocio exitosamente'
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @form, alert: "❌ Error al convertir: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error en convert_to_transaction: #{e.class} - #{e.message}"
    redirect_to @form, alert: "❌ Error inesperado: #{e.message}"
  end
end



  def convert_to_transaction_anterior
    @form = InitialContactForm.find(params[:id])
    
    begin
      ActiveRecord::Base.transaction do
        # ========================================
        # 1. CREAR O ACTUALIZAR CLIENTE
        # ========================================
        @client = Client.from_initial_contact_form(@form)
        
        unless @client.save
          raise ActiveRecord::RecordInvalid, @client
        end

        @form.update!(client_id: @client.id)

        # ========================================
        # 2. CALCULAR PRECIO (FUERA DEL HASH)
        # ========================================
        asking_price = @form.property_info&.dig('asking_price').to_f || 1.0
        final_price = asking_price.positive? ? asking_price : 1.0

        # ========================================
        # 3. CREAR TRANSACCIÓN COMERCIAL
        # ========================================
        @transaction = BusinessTransaction.create!(
          offering_client_id: @client.id,
          property_id: @form.property_id,
          listing_agent_id: current_user.id,
          current_agent_id: current_user.id,
          operation_type_id: @form.operation_type_id,
          business_status_id: BusinessStatus.find_by(name: 'prospecto')&.id || BusinessStatus.first&.id,
          price: final_price,
          commission_percentage: 0,
          start_date: Date.current,
          property_acquisition_method_id: @form.property_acquisition_method_id
        )

        # ========================================
        # 4. CREAR CO-PROPIETARIOS
        # ========================================

        raw_count = @form.acquisition_details&.dig('co_owners_count').to_i
        coowners_count = raw_count > 0 ? raw_count : 1  # Evita división por cero

        percentage_per_owner = (100.0 / coowners_count).round(2)

        
        # coowners_count = @form.acquisition_details&.dig('coowners_count').to_i || 1
        # percentage_per_owner = (100.0 / coowners_count).round(2)

        BusinessTransactionCoOwner.create!(
          business_transaction_id: @transaction.id,
          client_id: @client.id,
          person_name: @client.display_name,
          percentage: percentage_per_owner,
          role: 'propietario',
          active: true
        )

        (coowners_count - 1).times do |i|
          BusinessTransactionCoOwner.create!(
            business_transaction_id: @transaction.id,
            client_id: nil,
            person_name: "Copropietario #{i + 2} - Pendiente",
            percentage: percentage_per_owner,
            role: 'copropietario',
            active: false
          )
        end

        # ========================================
        # 5. ACTUALIZAR ESTADO DEL FORMULARIO
        # ========================================
        @form.update!(
          business_transaction_id: @transaction.id,
          status: :converted,
          converted_at: Time.current
        )

        redirect_to business_transaction_path(@transaction), 
                    notice: '✅ Convertido a Transacción de Negocio exitosamente'
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to @form, alert: "❌ Error al convertir: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "Error en convert_to_transaction: #{e.class} - #{e.message}"
      redirect_to @form, alert: "❌ Error inesperado: #{e.message}"
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
  @form = InitialContactForm.find(params[:id])
  
  # En lugar de renderizar un modal, redirigir al CRUD de clientes
  redirect_to edit_client_path(@form.id), notice: 'Editar datos del cliente'
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



  # Redirigir a CRUD de cliente
  def new_client_for_form
    @form = InitialContactForm.find(params[:id])
    
    # Crear un cliente asociado a este formulario
    # Por ahora, solo redirigir a nueva página de cliente
    # Luego se puede mejorar para pre-llenar datos
    
    redirect_to new_client_path(form_id: @form.id), notice: 'Edita los datos del cliente'
  end

  # Redirigir a CRUD de propiedad
  def new_property_for_form
    @form = InitialContactForm.find(params[:id])
    
    # Crear una propiedad asociada a este formulario
    # Por ahora, solo redirigir a nueva página de propiedad
    
    redirect_to new_property_path(form_id: @form.id), notice: 'Edita los datos de la propiedad'
  end

  # Método antiguo para compatibilidad (opcional, puede eliminarse después)
  def edit_client_modal_anterior
    @form = InitialContactForm.find(params[:id])
    @general_conditions = @form.general_conditions || {}
    
    respond_to do |format|
      format.turbo_stream
      format.html { render :edit_client_modal, layout: false }
    end
  end




  def update_client_from_modal
    @form = InitialContactForm.find(params[:id])
    general_conditions = @form.general_conditions || {}
    
    general_conditions['owner_or_representative_name'] = params.dig(:general_conditions, :owner_or_representative_name) || general_conditions['owner_or_representative_name']
    general_conditions['owner_phone'] = params.dig(:general_conditions, :owner_phone) || general_conditions['owner_phone']
    general_conditions['owner_email'] = params.dig(:general_conditions, :owner_email) || general_conditions['owner_email']
    general_conditions['civil_status'] = params.dig(:general_conditions, :civil_status) || general_conditions['civil_status']
    general_conditions['marriage_regime_id'] = params.dig(:general_conditions, :marriage_regime_id) || general_conditions['marriage_regime_id']
    general_conditions['notes'] = params.dig(:general_conditions, :notes) || general_conditions['notes']
    
    if @form.update(general_conditions: general_conditions)
      respond_to do |format|
        format.json { render json: { success: true, message: 'Cliente actualizado' } }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @form.errors }, status: :unprocessable_entity }
      end
    end
  end

  private

  def create_co_owners!(transaction)
    # Extraer conteo desde acquisition_details
    count = (@form.acquisition_details['co_owners_count'] || 1).to_i
    
    # Calcular porcentaje
    percentage_each = (100.0 / count).round(2)
    
    # Crear copropietario principal
    transaction.business_transaction_co_owners.create!(
      client: transaction.offering_client,
      person_name: @form.general_conditions['owner_or_representative_name'],
      percentage: percentage_each,
      role: 'propietario',
      active: true
    )
    
    # Crear placeholders para los demás
    if count > 1
      (count - 1).times do |i|
        transaction.business_transaction_co_owners.create!(
          person_name: "Copropietario #{i + 2} - Por definir",
          percentage: percentage_each,
          role: 'copropietario',
          active: true
        )
      end
    end
  end

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
        :first_names,
        :first_surname,
        :second_surname,
        :owner_or_representative_name,
        :owner_phone,
        :owner_email,
        :owner_address,
        :domicile_type,
        :civil_status,
        :marriage_regime_id,
        :current_civil_status,
        :current_marriage_regime_id,
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
