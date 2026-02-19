class BusinessTransaction < ApplicationRecord
  include FolioGenerator
  belongs_to :listing_agent, class_name: "User"
  belongs_to :current_agent, class_name: "User"
  belongs_to :selling_agent, class_name: "User", optional: true
  belongs_to :offering_client, class_name: "Client"
  belongs_to :acquiring_client, class_name: "Client", optional: true
  belongs_to :property
  belongs_to :operation_type
  belongs_to :business_status
  belongs_to :transaction_scenario, optional: true
  belongs_to :co_ownership_type, optional: true
  belongs_to :property_acquisition_method, optional: true
 
  after_create :assign_transaction_scenario_by_category
  after_create :set_primary_coowner_from_legal_representation
  after_commit :setup_documents_on_creation, on: :create
  after_commit :setup_documents_for_new_coowners, on: :update
  after_commit :update_primary_coowner_flag, on: :update
  after_save :check_ownership_percentage_total

  before_destroy :check_active_offers  
  before_destroy :reset_initial_contact_form  

  has_one :initial_contact_form, dependent: :nullify

  has_many :document_submissions, dependent: :destroy
  has_many :agent_transfers, dependent: :destroy
  has_many :business_transaction_co_owners, inverse_of: :business_transaction, dependent: :destroy
  has_many :offers, dependent: :destroy
  alias_method :co_owners, :business_transaction_co_owners
  
  accepts_nested_attributes_for :business_transaction_co_owners,
    allow_destroy: true,
    reject_if: proc { |attrs|
      Rails.logger.info "🔍 REJECT_IF evaluando: #{attrs.inspect}"
      should_reject = attrs['client_id'].blank? && attrs['person_name'].blank?

      Rails.logger.info "🔍 NESTED ATTRS COPROPIETARIO:"
      Rails.logger.info "   client_id: #{attrs['client_id'].inspect}"
      Rails.logger.info "   person_name: #{attrs['person_name'].inspect}"
      Rails.logger.info "   role: #{attrs['role'].inspect}"
      Rails.logger.info "   percentage: #{attrs['percentage'].inspect}"
      Rails.logger.info "   _destroy: #{attrs['_destroy'].inspect}"
      Rails.logger.info "   → RECHAZAR: #{should_reject}"
      
      should_reject

    }
  accepts_nested_attributes_for :property, allow_destroy: false, reject_if: :all_blank

  validates :start_date, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validate :validate_acquisition_method_requirements
 
  scope :active, -> { joins(:business_status).where(business_statuses: { name: ["available", "reserved"] }) }
  scope :completed, -> { joins(:business_status).where(business_statuses: { name: ["sold", "rented"] }) }
  

  # Método unificado para obtener el agente responsable
  def assigned_agent
    current_agent || selling_agent || listing_agent
  end

  # Helper para email con fallback
  def assigned_agent_email
    assigned_agent&.email || 'sin-agente@sistemainm.local'
  end

  # Helper para nombre completo
  def assigned_agent_name
    assigned_agent&.full_name || assigned_agent&.email || 'Sin agente asignado'
  end
def audit_trail
  []  # Retorna array vacío por ahora
end

def co_ownership_notes
  nil  # O retorna un valor por defecto
end

  def transfer_to_agent!(new_agent, reason, transferred_by)
    transaction do
      agent_transfers.create!(
        from_agent: current_agent,
        to_agent: new_agent,
        transferred_by: transferred_by,
        reason: reason,
        transferred_at: Time.current
      )
      update!(current_agent: new_agent)
    end
  end
  def revenue
    return 0 unless completed?
    (price * (commission_percentage || 0) / 100).round(2)
  end

  def completed?
    %w[sold rented].include?(business_status.name)
  end

  def available?
    business_status.name == "available"
  end

  def total_ownership_percentage
    business_transaction_co_owners.active.sum(:percentage)
  end

  def is_single_owner?
    business_transaction_co_owners.active.count == 1
  end

  
def generate_property_identifier(operation_type_code, property_name)
  sanitized_name = StringNormalizer.unaccent(property_name)
    .strip
    .downcase
    .gsub(/[^a-z0-9\s-]/, '')
    .gsub(/[\s-]+/, '_')
    .gsub(/^_|_$/, '')

  "#{operation_type_code}_#{sanitized_name}"
end


 
  
  def create_required_documents_v2!(scenario)
    return unless scenario.present?

    Rails.logger.info "=" * 80
    Rails.logger.info "📋 CREANDO DOCUMENTOS REQUERIDOS - V2 (SIN DUPLICADOS)"
    Rails.logger.info "BT ID: #{id} | Scenario: #{scenario.name}"
    Rails.logger.info "=" * 80

    # Rastrear documentos creados para evitar duplicados en el mismo proceso
    created_doc_map = {}  # { "doc_type_id:party_type" => true }

    scenario.scenario_documents.each do |scenario_doc|
      doc_type = scenario_doc.document_type
      party_type = scenario_doc.party_type
      only_principal = scenario_doc.only_for_principal?

      # CLAVE DEDUPLICACIÓN: Prevenir documentos duplicados
      # Si ya procesamos este tipo de documento para este tipo de parte en este loop, saltamos.
      doc_key = "#{doc_type.id}:#{party_type}"
      
      if created_doc_map[doc_key]
        Rails.logger.info "⏭️  SALTANDO DUPLICADO: #{doc_type.name} (#{party_type}) - YA CREADO"
        next
      end

      Rails.logger.info "\n🔍 Procesando: #{doc_type.name}"
      Rails.logger.info "   party_type: #{party_type}"
      Rails.logger.info "   only_principal: #{only_principal}"

      # Determinar copropietarios destino
      target_co_owners = if only_principal
                           business_transaction_co_owners.where(role: 'propietario')
                         else
                           map_party_type_to_co_owners(party_type)
                         end

      Rails.logger.info "   Creando para #{target_co_owners.count} copropietario(s):"

      target_co_owners.each do |co_owner|
        Rails.logger.info "      → #{co_owner.person_name} (#{co_owner.role})"

        # CLAVE IDEMPOTENCIA: find_or_create_by previene duplicados en BD
        # Si se corre el proceso dos veces, no crea dobles.
        submission = DocumentSubmission.find_or_create_by!(
          business_transaction_id: id,
          business_transaction_co_owner_id: co_owner.id,
          document_type_id: doc_type.id
        ) do |sub|
          sub.party_type = party_type
          sub.notes = "Requerido por escenario: #{scenario.name}"
          # Si necesitas copiar más atributos del scenario_doc, hazlo aquí
        end

        Rails.logger.info "         ✅ DocSub ID: #{submission.id}"
      end

      # Marcar como creado para esta combinación
      created_doc_map[doc_key] = true
    end

    Rails.logger.info "\n" + "=" * 80
    Rails.logger.info "✅ RESUMEN FINAL"
    Rails.logger.info "   Documento combinations procesadas: #{created_doc_map.count}"
    Rails.logger.info "   Total DocumentSubmissions: #{document_submissions.count}"
    Rails.logger.info "=" * 80
  end



  private

  def check_ownership_percentage_total
    return if business_transaction_co_owners.empty?

    active_co_owners = business_transaction_co_owners.where(active: true)
    return if active_co_owners.empty?

    total = active_co_owners.sum(:percentage)

    if total < 100
      Rails.logger.warn "⚠️  BT ##{id}: Porcentajes suman #{total.round(2)}% (venta parcial)"
    elsif total > 100
      Rails.logger.warn "⚠️  BT ##{id}: Porcentajes suman #{total.round(2)}% (revisar datos)"
    else
      Rails.logger.info "✅ BT ##{id}: Porcentajes suman 100%"
    end
  end



  def set_primary_coowner_from_legal_representation
    return unless legal_representation.is_a?(Hash)
    return if business_transaction_co_owners.empty?
    
    principal_name = legal_representation.dig('owner_name')
    
    principal = if principal_name.present?
                  # Buscar por nombre en legal_representation
                  business_transaction_co_owners.find do |co|
                    co.person_name == principal_name || 
                    co.client&.display_name == principal_name
                  end
                else
                  # Fallback: usar lógica legacy
                  business_transaction_co_owners.find(&:should_be_primary?) ||
                  business_transaction_co_owners.order(:id).first
                end
    
    if principal
      principal.update_column(:is_primary, true)
      Rails.logger.info "✅ Principal auto-asignado: #{principal.display_name}"
    end
  end



  def update_primary_coowner_flag
    return unless legal_representation.is_a?(Hash)
    
    principal_name = legal_representation.dig('owner_name')
    return if principal_name.blank?
    
    # Encontrar el copropietario que coincide con owner_name
    new_principal = business_transaction_co_owners.where(active: true).find do |co|
      co.person_name == principal_name || co.client&.display_name == principal_name
    end
    
    return unless new_principal
    
    # Si cambió el principal, actualizar flags
    current_primary = business_transaction_co_owners.find_by(is_primary: true)
    
    if current_primary&.id != new_principal.id
      Rails.logger.info "🔄 Cambiando copropietario principal: #{current_primary&.display_name} → #{new_principal.display_name}"
      
      # Quitar flag del anterior
      current_primary&.update_column(:is_primary, false)
      
      # Asignar flag al nuevo
      new_principal.update_column(:is_primary, true)
      
      # ✅ REASIGNAR DOCUMENTOS DE PRINCIPAL
      reassign_principal_documents(current_primary, new_principal)
    end
  end

  def reassign_principal_documents(old_principal, new_principal)
    return unless old_principal && new_principal
    
    # Documentos que solo debe tener el principal
    principal_docs = document_submissions.where(
      party_type: 'copropietario_principal',
      business_transaction_co_owner: old_principal
    )
    
    Rails.logger.info "   Reasignando #{principal_docs.count} documentos principales"
    
    principal_docs.each do |doc|
      # Verificar si el nuevo principal ya tiene este tipo de documento
      existing = document_submissions.find_by(
        document_type: doc.document_type,
        party_type: 'copropietario_principal',
        business_transaction_co_owner: new_principal
      )
      
      if existing
        # Ya existe, eliminar el del anterior
        doc.destroy
      else
        # Reasignar al nuevo principal
        doc.update_column(:business_transaction_co_owner_id, new_principal.id)
      end
    end
    
    # Cambiar los documentos del viejo principal a tipo 'copropietario'
    document_submissions.where(
      party_type: 'copropietario_principal',
      business_transaction_co_owner: old_principal
    ).update_all(party_type: 'copropietario')
    
    # Generar documentos principales faltantes para el nuevo
    transaction_scenario
      .scenario_documents
      .for_party('copropietario_principal')
      .required
      .includes(:document_type)
      .each do |sc_doc|
        document_submissions.find_or_create_by!(
          document_type: sc_doc.document_type,
          party_type: 'copropietario_principal',
          business_transaction_co_owner: new_principal
        ) do |ds|
          ds.document_status = DocumentStatus.find_by(name: 'pendiente_solicitud')
        end
      end
    
    Rails.logger.info "✅ Documentos reasignados correctamente"
  end

  def setup_documents_for_new_coowners
    return unless transaction_scenario.present?
    
    Rails.logger.info "🔍 Verificando nuevos copropietarios para generar documentos..."
    
    # ✅ IDENTIFICAR AL PRINCIPAL desde legal_representation
    principal_name = legal_representation.dig('owner_name') if legal_representation.is_a?(Hash)
    
    principal_co_owner = if principal_name.present?
                          # Buscar por coincidencia de nombre
                          business_transaction_co_owners
                            .where(active: true)
                            .find { |co| co.person_name == principal_name || co.client&.display_name == principal_name }
                        else
                          # Fallback: el primero creado
                          business_transaction_co_owners.where(active: true).order(:id).first
                        end
    
    if principal_co_owner
      Rails.logger.info "   Principal identificado: #{principal_co_owner.display_name} (ID: #{principal_co_owner.id})"
      principal_co_owner.update_column(:is_primary, true) unless principal_co_owner.is_primary
    else
      Rails.logger.warn "⚠️  No se pudo identificar al copropietario principal"
    end
    
    # Buscar copropietarios SIN documentos
    business_transaction_co_owners.where(active: true).each do |co_owner|
      next if co_owner.document_submissions.any?
      
      is_primary = (co_owner.id == principal_co_owner&.id)
      party_type = is_primary ? 'copropietario_principal' : 'copropietario'
      
      Rails.logger.info "📄 Generando documentos para #{co_owner.display_name}"
      Rails.logger.info "   → Es principal: #{is_primary} | party_type: #{party_type}"
      
      # Generar documentos según escenario
      transaction_scenario
        .scenario_documents
        .for_party(party_type)
        .required
        .includes(:document_type)
        .each do |sc_doc|
          document_submissions.find_or_create_by!(
            document_type: sc_doc.document_type,
            party_type: party_type,
            business_transaction_co_owner: co_owner
          ) do |ds|
            ds.document_status = DocumentStatus.find_by(name: 'pendiente_solicitud')
            
            # Calcular fecha de expiración
            metadata_validity = sc_doc.document_type.metadata.is_a?(Hash) ? 
                                sc_doc.document_type.metadata['validity_months'] : nil
            
            if metadata_validity.present? && metadata_validity.to_i.positive?
              ds.expiry_date = Date.current + metadata_validity.to_i.months
            end
          end
        end
      
      Rails.logger.info "✅ Documentos generados para #{co_owner.display_name}"
    end
  end


  def setup_documents_for_new_coowners_anterior_1
    return unless transaction_scenario.present?
    
    Rails.logger.info "🔍 Verificando nuevos copropietarios para generar documentos..."
    
    # ✅ IDENTIFICAR CORRECTAMENTE AL PRINCIPAL
    # El principal es el primer co_owner con role != 'copropietario' o el primero si todos son iguales
    principal_co_owner = business_transaction_co_owners
                          .order(:id)  # Ordenar por ID (el primero creado)
                          .where(active: true)
                          .first
    
    Rails.logger.info "   Principal: #{principal_co_owner&.display_name} (ID: #{principal_co_owner&.id})"
    
    # Buscar copropietarios SIN documentos
    business_transaction_co_owners.where(active: true).each do |co_owner|
      next if co_owner.document_submissions.any?
      
      Rails.logger.info "📄 Generando documentos para nuevo copropietario #{co_owner.id} (#{co_owner.display_name})"
      
      # ✅ DETERMINAR SI ES PRINCIPAL O ADICIONAL
      is_primary = (co_owner.id == principal_co_owner&.id)
      party_type = is_primary ? 'copropietario_principal' : 'copropietario'
      
      Rails.logger.info "   → Es principal: #{is_primary} | party_type: #{party_type}"
      
      # Generar documentos según escenario
      transaction_scenario
        .scenario_documents
        .for_party(party_type)
        .required
        .includes(:document_type)
        .each do |sc_doc|
          document_submissions.find_or_create_by!(
            document_type: sc_doc.document_type,
            party_type: party_type,
            business_transaction_co_owner: co_owner
          ) do |ds|
            ds.document_status = DocumentStatus.find_by(name: 'pendiente_solicitud')
            
            # Calcular fecha de expiración
            metadata_validity = sc_doc.document_type.metadata.is_a?(Hash) ? 
                                sc_doc.document_type.metadata['validity_months'] : nil
            
            if metadata_validity.present? && metadata_validity.to_i.positive?
              ds.expiry_date = Date.current + metadata_validity.to_i.months
            end
          end
        end
      
      Rails.logger.info "✅ Documentos generados para #{co_owner.display_name}"
    end
  end



  def setup_documents_for_new_coowners_anterior
    return unless transaction_scenario.present?
    
    Rails.logger.info "🔍 Verificando nuevos copropietarios para generar documentos..."
    
    # Buscar copropietarios SIN documentos
    business_transaction_co_owners.where(active: true).each do |co_owner|
      next if co_owner.document_submissions.any?
      
      Rails.logger.info "📄 Generando documentos para nuevo copropietario #{co_owner.id} (#{co_owner.display_name})"
      
      # Determinar si es principal o adicional
      is_primary = business_transaction_co_owners.order(:id).first.id == co_owner.id
      party_type = is_primary ? 'copropietario_principal' : 'copropietario'
      
      # Generar documentos según escenario
      transaction_scenario
        .scenario_documents
        .for_party(party_type)
        .required
        .includes(:document_type)
        .each do |sc_doc|
          document_submissions.find_or_create_by!(
            document_type: sc_doc.document_type,
            party_type: party_type,
            business_transaction_co_owner: co_owner
          ) do |ds|
            ds.document_status = DocumentStatus.find_by(name: 'pendiente_solicitud')
            
            # Calcular fecha de expiración
            metadata_validity = sc_doc.document_type.metadata.is_a?(Hash) ? 
                                sc_doc.document_type.metadata['validity_months'] : nil
            
            if metadata_validity.present? && metadata_validity.to_i.positive?
              ds.expiry_date = Date.current + metadata_validity.to_i.months
            end
          end
        end
      
      Rails.logger.info "✅ Documentos generados para #{co_owner.display_name}"
    end
  end


  def map_party_type_to_co_owners(party_type)
      case party_type
      when 'copropietario_principal', 'propietario', 'vendedor', 'dueño'
        # Ajusta estos roles según tu lógica de negocio exacta
        business_transaction_co_owners.where(role: 'propietario')
      when 'adquiriente', 'comprador', 'arrendatario'
        # Generalmente los documentos de adquiriente se manejan diferente o no tienen co-owners,
        # pero si tienes co-owners tipo 'comprador', agrégalos aquí.
        # Si 'adquiriente' es solo la contraparte y no está en co_owners, retorna vacío.
        [] 
      when 'copropietario'
        business_transaction_co_owners.where(role: ['propietario', 'copropietario'])
      when 'ambos', 'todos'
        business_transaction_co_owners
      else
        []
      end
    end



  # ============================================================
  # VALIDACIÓN: No borrar si hay ofertas activas
  # ============================================================
  def check_active_offers
    if offers.active.exists?
      errors.add(:base, "No se puede borrar: hay ofertas activas en progreso. Rechaza o cancela todas las ofertas primero.")
      throw :abort
    end
  end


  # ============================================================
  # CALLBACK: Reestablecer InitialContactForm cuando se borra BT
  # ============================================================
  def reset_initial_contact_form
    return unless initial_contact_form.present?
    
    initial_contact_form.update!(
      status: :completed,
      business_transaction_id: nil
    )
    
    Rails.logger.info "✅ InitialContactForm #{initial_contact_form.id} reestablecida a estado 'completed'"
  end
  
  def validate_acquisition_method_requirements
    return unless property_acquisition_method.present?
    
    if property_acquisition_method.requires_heirs? && 
       inheritance_details['heirs_count'].blank?
      errors.add(:inheritance_details, "es requerido para #{property_acquisition_method.name}")
    end
    
    if property_acquisition_method.requires_judicial_sentence? && 
       inheritance_details['judicial_sentence_number'].blank?
      errors.add(:inheritance_details, "debe incluir número de sentencia judicial")
    end
  end


# ============================================================
# CALLBACK 1: Asignar TransactionScenario automáticamente
# ============================================================
def assign_transaction_scenario_by_category
  return if transaction_scenario.present?  # Si ya tiene scenario, no hacer nada
  
  # Determinar category basado en operation_type.name
  category = determine_scenario_category
  return unless category
  
  # Buscar scenario por categoría
  scenario = TransactionScenario.find_by(category: category, active: true)
  
  if scenario
    update_column(:transaction_scenario_id, scenario.id)
    Rails.logger.info "✅ Scenario asignado automáticamente: #{scenario.name}"
  else
    Rails.logger.warn "⚠️  No se encontró scenario para categoría: #{category}"
  end
rescue StandardError => e
  Rails.logger.error "❌ Error asignando scenario: #{e.message}"
end


# Determinar categoría del scenario basado en operation_type
def determine_scenario_category
  return nil unless operation_type.present?
  
  case operation_type.name
  when 'sale'
    'compraventa'
  when 'rent'
    # Detectar si es habitacional o comercial
    if property&.property_type&.name.to_s.include?('apartment') || 
       property&.property_type&.name.to_s.include?('house')
      'renta_habitacional'
    else
      'renta_comercial'
    end
  else
    nil
  end
end


# ============================================================
# CALLBACK 2: Crear DocumentSubmissions requeridos
# ============================================================


  def setup_documents_on_creation
    return if initial_contact_form.present?
    return unless transaction_scenario.present?

    
    DocumentSetupService.new(self).setup_required_documents
  rescue StandardError => e
    Rails.logger.error "❌ Error creando documentos para transacción #{id}: #{e.message}"
    raise
  end


  def must_have_co_owners
    active_co_owners = if new_record?
                         business_transaction_co_owners.reject(&:marked_for_destruction?)
                       else
                         business_transaction_co_owners.where(active: true)
                       end

    if active_co_owners.empty?
      errors.add(:business_transaction_co_owners, "Debe tener al menos un propietario/copropietario")
    end
  end

  def ownership_percentages_sum_to_100
    return if business_transaction_co_owners.empty?

    active_co_owners = if new_record?
                         business_transaction_co_owners.reject(&:marked_for_destruction?)
                       else
                         business_transaction_co_owners.where(active: true)
                       end

    return if active_co_owners.empty?

    total = active_co_owners.sum(&:percentage)

    unless total.round(2) == 100.0
      errors.add(:business_transaction_co_owners, "Los porcentajes deben sumar exactamente 100% (actual: #{total.round(2)}%)")
    end
  end
end