# app/jobs/document_analysis_job.rb
# Job asíncrono para análisis de documentos

class DocumentAnalysisJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(submission_id)
    submission = DocumentSubmission.find(submission_id)
    
    Rails.logger.info "🔍 Analizando documento ##{submission_id}..."
    
    service = DocumentAnalysisService.new(submission)
    result = service.analyze
    
    # Notificar al usuario via Turbo Stream si está conectado
    broadcast_analysis_complete(submission)
    
    Rails.logger.info "✅ Análisis completado para documento ##{submission_id}"
    Rails.logger.info "   - Legibilidad: #{submission.legibility_score}%"
    Rails.logger.info "   - OCR extraído: #{submission.ocr_text.present? ? 'Sí' : 'No'}"
    Rails.logger.info "   - Auto-validado: #{submission.auto_validated? ? 'Sí' : 'No'}"
    
    result
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "❌ DocumentSubmission ##{submission_id} no encontrado"
  rescue StandardError => e
    Rails.logger.error "❌ Error analizando documento ##{submission_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  private

  def broadcast_analysis_complete(submission)
    # Broadcast via Turbo Stream (opcional, para updates en tiempo real)
    # Turbo::StreamsChannel.broadcast_replace_to(
    #   "document_#{submission.id}",
    #   target: "document_#{submission.id}",
    #   partial: "document_submissions/document_card",
    #   locals: { submission: submission }
    # )
  end
end
