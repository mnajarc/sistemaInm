class DocumentSetupService
  def initialize(transaction)
    @transaction = transaction
  end

  def setup_required_documents_anterior
    return unless @transaction.transaction_scenario

    ActiveRecord::Base.transaction do
      setup_for('oferente')
      setup_for('adquiriente') if @transaction.acquiring_client
    end
  end

  def setup_required_documents
    return unless @transaction.transaction_scenario

    ActiveRecord::Base.transaction do
      setup_for_copropietarios
      setup_for('adquiriente') if @transaction.acquiring_client
    end
  end


  def setup_required_documents_anterior
    return unless @transaction.transaction_scenario

    ActiveRecord::Base.transaction do
      # Solo crea para copropietarios (que incluye al oferente/propietario principal)
      setup_for_copropietarios
      
      # Y para adquiriente si existe (persona que compra, no es copropietario de la propiedad)
      setup_for('adquiriente') if @transaction.acquiring_client
    end
  end


  private

  def setup_for_copropietarios
    co_owners = @transaction.business_transaction_co_owners.all
    
    return if co_owners.empty?
    
    co_owners.each_with_index do |co_owner, index|
      # El primero es el principal, los demás son copropietarios adicionales
      party_type = index.zero? ? 'copropietario_principal' : 'copropietario'
      
      @transaction.transaction_scenario
                  .scenario_documents
                  .for_party(party_type)
                  .required
                  .includes(:document_type)
                  .each do |sc_doc|
        @transaction.document_submissions.find_or_create_by!(
          document_type: sc_doc.document_type,
          party_type: party_type,
          business_transaction_co_owner: co_owner
        ) do |ds|
          ds.document_status = DocumentStatus.pendiente_solicitud
          ds.expiry_date = calculate_expiry(sc_doc)
        end
      end
    end
  end

  def setup_for(party)
    @transaction.transaction_scenario
                .scenario_documents
                .for_party(party)
                .required
                .includes(:document_type)
                .each do |sc_doc|
      @transaction.document_submissions.find_or_create_by!(
        document_type: sc_doc.document_type,
        party_type: party
      ) do |ds|
        ds.document_status = DocumentStatus.pendiente_solicitud
        ds.expiry_date = calculate_expiry(sc_doc)
      end
    end
  end

  def setup_for_anterior(party)
    @transaction.transaction_scenario
                .scenario_documents
                .for_party(party)
                .required
                .includes(:document_type)
                .each do |sc_doc|
      @transaction.document_submissions.find_or_create_by!(
        document_type: sc_doc.document_type,
        party_type: party
      ) do |ds|
        ds.document_status = DocumentStatus.pendiente_solicitud
        ds.expiry_date = calculate_expiry(sc_doc)
      end
    end
  end

  def setup_for_copropietarios_anterior
    # Obtener TODOS los copropietarios (incluyendo al oferente/propietario)
    co_owners = @transaction.business_transaction_co_owners.all
    
    return if co_owners.empty?
    
    # Para cada copropietario, crear sus documentos
    co_owners.each do |co_owner|
      @transaction.transaction_scenario
                  .scenario_documents
                  .for_party('copropietario')
                  .required
                  .includes(:document_type)
                  .each do |sc_doc|
        @transaction.document_submissions.find_or_create_by!(
          document_type: sc_doc.document_type,
          party_type: 'copropietario',
          business_transaction_co_owner: co_owner
        ) do |ds|
          ds.document_status = DocumentStatus.pendiente_solicitud
          ds.expiry_date = calculate_expiry(sc_doc)
        end
      end
    end
  end

  def calculate_expiry(scenario_doc)
    type = scenario_doc.document_type
    metadata_validity = type.metadata.is_a?(Hash) ? type.metadata['validity_months'] : nil

    if metadata_validity.present? && metadata_validity.to_i.positive?
      Date.current + metadata_validity.to_i.months
    else
      nil
    end
  end


  def setup_for_anterior0(party)
    @transaction.transaction_scenario
                .scenario_documents
                .for_party(party)
                .required
                .includes(:document_type)
                .each do |sc_doc|
      @transaction.document_submissions.find_or_create_by!(
        document_type: sc_doc.document_type,
        party_type: party
      ) do |ds|
        ds.document_status = DocumentStatus.pendiente_solicitud
        ds.expiry_date = calculate_expiry(sc_doc)
      end
    end
  end

  def calculate_expiry_anterior0(scenario_doc)
    type = scenario_doc.document_type
    metadata_validity = type.metadata.is_a?(Hash) ? type.metadata['validity_months'] : nil

    if metadata_validity.present? && metadata_validity.to_i.positive?
      Date.current + metadata_validity.to_i.months
    else
      nil
    end
  end

end
