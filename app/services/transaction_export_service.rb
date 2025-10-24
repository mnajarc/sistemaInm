# app/services/transaction_export_service.rb
# VERSIÓN CORREGIDA

class TransactionExportService
  attr_reader :transaction, :base_path, :export_path

  def initialize(business_transaction, base_path: '/mnt/nas_docs')
    @transaction = business_transaction
    @base_path = base_path
    @export_path = nil
  end

  def export
    create_transaction_folder
    export_oferente
    export_adquiriente if @transaction.acquiring_client.present?
    export_copropietarios
    create_metadata_file
    
    {
      success: true,
      path: @export_path,
      files_exported: count_exported_files,
      message: "Documentos exportados exitosamente a #{@export_path}"
    }
  rescue StandardError => e
    Rails.logger.error "Error exportando transacción: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    {
      success: false,
      error: e.message,
      message: "Error al exportar documentos: #{e.message}"
    }
  end

  private

  def create_transaction_folder
    folder_name = generate_folder_name
    @export_path = File.join(@base_path, folder_name)
    FileUtils.mkdir_p(@export_path)
    
    Rails.logger.info "📂 Carpeta creada: #{@export_path}"
  end

  def get_agent_email
    # Usar current_agent primero (es el actualmente asignado)
    return @transaction.current_agent&.email if @transaction.current_agent.present?
    return @transaction.listing_agent&.email if @transaction.listing_agent.present?
    return @transaction.selling_agent&.email if @transaction.selling_agent.present?
    'N/A'
  end

  
  def generate_folder_name
    date = @transaction.created_at.strftime('%Y-%m-%d')
    property_name = @transaction.property.address.parameterize(separator: '_').first(30)
    
    "transaccion_#{@transaction.id}_#{date}_#{property_name}"
  end

  def export_oferente
    export_party('oferente', 'Oferente')
  end

  def export_adquiriente
    export_party('adquiriente', 'Adquiriente')
  end

  def export_party(party_type, folder_name)
    party_folder = File.join(@export_path, folder_name)
    FileUtils.mkdir_p(party_folder)
    
    submissions = @transaction.document_submissions
                              .where(party_type: party_type)
                              .includes(:document_type, :document_file_attachment)
    
    submissions.each do |submission|
      next unless submission.document_file.attached?
      
      export_file(submission, party_folder)
    end
    
    Rails.logger.info "✅ Exportados #{submissions.count} documentos de #{folder_name}"
  end

  def export_copropietarios
    co_owners = @transaction.business_transaction_co_owners.where(active: true)
    return if co_owners.empty?
    
    coprop_base_folder = File.join(@export_path, 'Copropietarios')
    FileUtils.mkdir_p(coprop_base_folder)
    
    co_owners.each do |co_owner|
      export_co_owner(co_owner, coprop_base_folder)
    end
  end

  def export_co_owner(co_owner, base_folder)
    owner_name = sanitize_filename(co_owner.person_name || co_owner.client&.name || "Copropietario_#{co_owner.id}")
    owner_folder = File.join(base_folder, owner_name)
    FileUtils.mkdir_p(owner_folder)
    
    submissions = @transaction.document_submissions
                              .where(party_type: 'copropietario',
                                     business_transaction_co_owner: co_owner)
                              .includes(:document_type, :document_file_attachment)
    
    submissions.each do |submission|
      next unless submission.document_file.attached?
      
      export_file(submission, owner_folder)
    end
    
    Rails.logger.info "✅ Exportados #{submissions.count} documentos de #{owner_name}"
  end

  def export_file(submission, destination_folder)
    filename = generate_friendly_filename(submission)
    dest_path = File.join(destination_folder, filename)
    
    File.open(dest_path, 'wb') do |file|
      file.write(submission.document_file.download)
    end
    
    if submission.submitted_at.present?
        # Convertir TimeWithZone a Unix timestamp
        timestamp = submission.submitted_at.to_i
        File.utime(timestamp, timestamp, dest_path)
    end
    
    
    Rails.logger.debug "📄 Exportado: #{filename}"
  rescue StandardError => e
    Rails.logger.error "❌ Error exportando #{submission.id}: #{e.message}"
  end

  def generate_friendly_filename(submission)
    doc_type = sanitize_filename(submission.document_type.name)
    date = submission.submitted_at&.strftime('%Y-%m-%d') || 'sin_fecha'
    extension = File.extname(submission.document_file.filename.to_s)
    
    # Usar ID como orden (corregido)
    order = submission.document_type.id
    
    "#{order.to_s.rjust(2, '0')}_#{doc_type}_#{date}#{extension}"
  end

  def sanitize_filename(name)
    name.to_s
        .parameterize(separator: '_')
        .gsub(/[^a-z0-9_\-]/i, '')
        .first(50)
  end

  def create_metadata_file
    metadata_path = File.join(@export_path, '_INFO_TRANSACCION.txt')
    
    content = <<~INFO
      ================================================================================
      INFORMACIÓN DE LA TRANSACCIÓN
      ================================================================================
      
      ID Transacción: #{@transaction.id}
      Fecha de creación: #{@transaction.created_at.strftime('%d/%m/%Y %H:%M')}
      Fecha de exportación: #{Time.current.strftime('%d/%m/%Y %H:%M')}
      
      PROPIEDAD:
      #{@transaction.property.address}
      
      OFERENTE:
      #{@transaction.offering_client&.name || 'N/A'}
      Email: #{@transaction.offering_client&.email || 'N/A'}
      
      ADQUIRIENTE:
      #{@transaction.acquiring_client&.name || 'N/A'}
      Email: #{@transaction.acquiring_client&.email || 'N/A'}
      
      COPROPIETARIOS:
      #{copropietarios_info}
      
      AGENTE ASIGNADO:
      #{get_agent_email || @transaction.user&.email || 'N/A'}
      
      ESCENARIO:
      #{@transaction.transaction_scenario&.name || 'Sin escenario'}
      
      DOCUMENTOS EXPORTADOS:
      #{document_summary}
      
      ================================================================================
    INFO
    
    File.write(metadata_path, content)
    Rails.logger.info "📋 Metadata creada: #{metadata_path}"
  end

  def copropietarios_info
    co_owners = @transaction.business_transaction_co_owners.where(active: true)
    
    if co_owners.empty?
      "  Ninguno"
    else
      co_owners.map do |co|
        "  - #{co.person_name || co.client&.name} (#{co.percentage}% - #{co.role})"
      end.join("\n")
    end
  end

  def document_summary
    summary = []
    
    ['oferente', 'adquiriente', 'copropietario'].each do |party|
      count = @transaction.document_submissions
                          .where(party_type: party)
                          .joins(:document_file_attachment)
                          .count
      
      summary << "  #{party.capitalize}: #{count} documentos" if count > 0
    end
    
    summary.join("\n")
  end

  def count_exported_files
    @transaction.document_submissions
                .joins(:document_file_attachment)
                .count
  end
end
