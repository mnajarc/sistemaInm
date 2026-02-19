class DocumentSetupService
  def initialize(transaction)
    @transaction = transaction
  end


  def setup_required_documents
    return unless @transaction.transaction_scenario

    ActiveRecord::Base.transaction do
      setup_for_copropietarios
      setup_for('adquiriente') if @transaction.acquiring_client
    end
  end




  private

  def setup_for_copropietarios
    co_owners = @transaction.business_transaction_co_owners.where(active: true)
    return if co_owners.empty?
    
    # ✅ IDENTIFICAR AL PRINCIPAL
    principal = co_owners.find_by(is_primary: true) || co_owners.order(:id).first
    
    # Asegurar que tiene el flag
    principal.update_column(:is_primary, true) unless principal.is_primary
    
    Rails.logger.info "📋 Setup documentos para #{co_owners.count} copropietarios"
    Rails.logger.info "   Principal: #{principal.display_name} (ID: #{principal.id})"
    
    co_owners.each do |co_owner|
      # ✅ DETERMINAR party_type según is_primary
      party_type = co_owner.is_primary ? 'copropietario_principal' : 'copropietario'
      
      Rails.logger.info "   → #{co_owner.display_name}: #{party_type}"
      
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
    
    Rails.logger.info "✅ Setup completado"
  end


  def setup_for_copropietarios_anterior
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


  def calculate_expiry(scenario_doc)
    type = scenario_doc.document_type
    metadata_validity = type.metadata.is_a?(Hash) ? type.metadata['validity_months'] : nil

    if metadata_validity.present? && metadata_validity.to_i.positive?
      Date.current + metadata_validity.to_i.months
    else
      nil
    end
  end



end
