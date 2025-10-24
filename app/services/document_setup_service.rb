class DocumentSetupService
  def initialize(transaction)
    @transaction = transaction
  end

  def setup_required_documents
    return unless @transaction.transaction_scenario

    ActiveRecord::Base.transaction do
      setup_for('oferente')
      setup_for('adquiriente') if @transaction.acquiring_client
    end
  end

  private

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
