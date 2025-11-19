# app/controllers/initial_contact_forms_controller.rb
class InitialContactFormsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_form, only: [:show, :edit, :update, :destroy, :convert_to_transaction, :suggest_acquisition_method]
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
    
    # ═══════════════════════════════════════════════════════════════
    # NUEVO: Filtro por periodo
    # ═══════════════════════════════════════════════════════════════
    if params[:period].present?
      @forms = case params[:period]
      when 'today'
        @forms.where('created_at >= ?', Time.current.beginning_of_day)
      when 'week'
        @forms.where('created_at >= ?', Time.current.beginning_of_week)
      when 'month'
        @forms.where('created_at >= ?', Time.current.beginning_of_month)
      when 'quarter'
        @forms.where('created_at >= ?', 3.months.ago)
      when 'year'
        @forms.where('created_at >= ?', Time.current.beginning_of_year)
      else
        @forms
      end
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
        "property_human_identifier ILIKE ?", 
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
    @form = InitialContactForm.new(agent: current_user.agent)
    @acquisition_methods = PropertyAcquisitionMethod.active.ordered
    @contract_signers = ContractSignerType.active.ordered
    @marriage_regimes = MarriageRegime.active.ordered
    @operation_types = OperationType.active.order(:sort_order)
    @acquisition_method_codes = PropertyAcquisitionMethod.active.pluck(:id, :code).to_h.to_json.html_safe
  end
  



  def create
    @form = InitialContactForm.new(form_params.merge(agent: current_user.agent))
    
    @form.status = params[:save_draft] ? :draft : :completed
    
    if @form.save
      
      
      # Mensaje de éxito con aviso si fue auto-generado
      notice_message = if @form.auto_generated_identifier
                        '✅ Formulario creado exitosamente. ⚠️ Identificador de oportunidad generado automáticamente por falta de este.'
                      else
                        '✅ Formulario creado exitosamente'
                      end
      
      redirect_to @form, notice: notice_message
    else
      @acquisition_methods = PropertyAcquisitionMethod.active.ordered
      @contract_signers = ContractSignerType.active.ordered
      @marriage_regimes = MarriageRegime.active.ordered
      @operation_types = OperationType.active.by_sort_order
      @acquisition_method_codes = PropertyAcquisitionMethod.active.pluck(:id, :code).to_h.to_json.html_safe
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @form.update(form_params)
      # Actualizar status si se cambió
      if params[:save_draft]
        @form.update(status: :draft)
      elsif params[:complete]
        @form.update(status: :completed)
      end
      
      # Mensaje de éxito con aviso si fue auto-generado
      notice_message = if @form.auto_generated_identifier
                        '✅ Formulario actualizado exitosamente. ⚠️ Identificador de oportunidad generado automáticamente por falta de este.'
                      else
                        '✅ Formulario actualizado exitosamente'
                      end
      
      redirect_to @form, notice: notice_message
    else
      @acquisition_methods = PropertyAcquisitionMethod.active.ordered
      @contract_signers = ContractSignerType.active.ordered
      @marriage_regimes = MarriageRegime.active.ordered
      @operation_types = OperationType.active.by_sort_order
      @acquisition_method_codes = PropertyAcquisitionMethod.active.pluck(:id, :code).to_h.to_json.html_safe
      render :edit, status: :unprocessable_entity
    end
  end

  
  def edit
    @acquisition_methods = PropertyAcquisitionMethod.active.ordered
    @contract_signers = ContractSignerType.active.ordered
    @marriage_regimes = MarriageRegime.active.ordered
    @operation_types = OperationType.active.order(:sort_order)
    @acquisition_method_codes = PropertyAcquisitionMethod.active.pluck(:id, :code).to_h.to_json.html_safe
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
  

  private

  
  def set_form
    @form = InitialContactForm.find(params[:id])
  end
  
  def ensure_agent!
    return if current_user.superadmin? || current_user.admin?  # ← EXENTOS
    
    if current_user.agent.nil?
      redirect_to root_path, alert: '⚠️ No tienes un agente asignado.'
    end
  end

  def authorize_form
    return if current_user.superadmin? || current_user.admin?  # ← PUEDEN VER TODO
    
    # Agente normal solo ve sus formularios
    unless @form.agent.user == current_user
      redirect_to root_path, alert: '❌ No tienes permiso para acceder'
    end
  end

  

  def form_params
    params.require(:initial_contact_form).permit(
      # ============================================================
      # CAMPOS PRINCIPALES (NIVEL RAÍZ)
      # ============================================================
      :property_acquisition_method_id,
      :contract_signer_type_id,
      :operation_type_id,
      :client_id,
      :property_id,
      :status,
      :agent_notes,
      :form_source,
      :acquisition_clarification,
      :property_human_identifier,  # ✅ CAMPO CRÍTICO
      
      # ============================================================
      # GENERAL_CONDITIONS (JSONB)
      # ============================================================
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
      
      # ============================================================
      # ACQUISITION_DETAILS (JSONB)
      # ============================================================
      acquisition_details: [
        # Copropietarios
        :co_owners_count,
        :has_co_owners,
        
        # Ubicación y uso
        :state,
        :land_use,
        
        # Relaciones entre copropietarios
        :has_relationship,
        :relationship_type,
        
        # Adquisición temporal
        :acquired_pre_2014,
        
        # Herencia - Herederos
        :heirs_count,
        :all_living,
        :deceased_count,
        :all_married,
        :single_heirs_count,
        :deceased_civil_status,
        
        # Herencia - Causante
        :inheritance_from,
        :inheritance_from_other,
        :parents_were_married,
        :parents_marriage_regime,
        
        # Sucesión
        :has_testamentary_succession,
        :succession_planned_date,
        :succession_authority,
        :succession_type,
        :has_judicial_sentence,
        :has_notarial_deed,
        :document_type,
        
        # Donación
        :donor_name,
        :donor_relationship,
        :donor_relationship_other,
        :beneficiaries_count
      ],
      
      # ============================================================
      # PROPERTY_INFO (JSONB) - Si aplica
      # ============================================================
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
        :mortgage_bank
      ],
      
      # ============================================================
      # CURRENT_STATUS (JSONB)
      # ============================================================
      current_status: [
        # Hipoteca
        :has_active_mortgage,
        :mortgage_balance,
        :monthly_payment,
        :mortgage_payments_current,
        :in_collection_agency,
        :mortgage_notes,
        
        # Ampliaciones
        :has_extensions,
        :extensions_reported,
        :extensions_notes,
        
        # Adiciones
        :has_additions,
        :additions_registered,
        :additions_notes,
        
        # Remodelaciones
        :has_renovations,
        :knows_renovation_cost,
        :renovation_cost,
        :renovation_notes,
        
        # Condominio
        :is_in_condominium,
        :condominium_regime,
        :has_condominium_rules,
        :has_maintenance_clearance,
        
        # Unidades rentables
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
      
      # ============================================================
      # TAX_EXEMPTION (JSONB)
      # ============================================================
      tax_exemption: [
        :first_home_sale,
        :lived_last_5_years,
        :ine_matches_deed,
        :previous_sales_last_3_years,
        :previous_sale_date,
        :estimated_capital_gain,
        :qualifies_for_exemption
      ],
      
      # ============================================================
      # PROMOTION_PREFERENCES (JSONB)
      # ============================================================
      promotion_preferences: [
        :allows_signage,
        :allows_flyers_with_address,
        :allows_open_house,
        :preferred_contact_method,
        :contact_hours,
        :special_instructions,
        signage_types: []  # Array de strings
      ]
    )
  end



end
