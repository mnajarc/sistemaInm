# app/services/document_validation_service.rb
class DocumentValidationService
  def initialize(document_submission)
    @document = document_submission
  end

  # Aprobar documento
  def approve!(user, notes = nil)
    transaction do
      @document.update!(
        validation_status: 'approved',
        validation_user_id: user.id,
        validated_at: Time.current
      )
      
      add_system_note(user, "Documento aprobado", 'status_change')
      add_system_note(user, notes, 'comment') if notes.present?
      
      Rails.logger.info "✅ Documento #{@document.id} aprobado por #{user.email}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ Error aprobando documento: #{e.message}"
    raise
  end

  # Rechazar documento (pedir re-subir)
  def reject!(user, reason)
    transaction do
      @document.update!(
        validation_status: 'rejected',
        validation_user_id: user.id,
        submitted_at: nil  # Permite re-subir
      )
      
      add_system_note(user, "Documento rechazado: #{reason}", 'status_change')
      add_system_note(user, reason, 'comment') if reason.present?
      
      Rails.logger.info "❌ Documento #{@document.id} rechazado por #{user.email}: #{reason}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ Error rechazando documento: #{e.message}"
    raise
  end

  # Marcar como expirado
  def mark_expired!(user, reason = nil)
    transaction do
      @document.update!(
        validation_status: 'expired',
        validation_user_id: user.id
      )
      
      add_system_note(user, "Documento marcado como expirado", 'status_change')
      add_system_note(user, reason || "Vigencia vencida", 'comment')
      
      Rails.logger.info "⏰ Documento #{@document.id} marcado como expirado por #{user.email}"
    end
  rescue StandardError => e
    Rails.logger.error "❌ Error marcando documento como expirado: #{e.message}"
    raise
  end

  # Agregar nota
  def add_note(user, content)
    raise "Contenido vacío" if content.blank?
    
    @document.add_note(user, content, 'comment')
    Rails.logger.info "💬 Nota agregada a documento #{@document.id} por #{user.email}"
  rescue StandardError => e
    Rails.logger.error "❌ Error agregando nota: #{e.message}"
    raise
  end

  # Eliminar última nota propia
  def delete_last_note(user)
    last_note = @document.last_note
    
    raise "Sin notas para eliminar" unless last_note.present?
    raise "Solo puedes borrar tus propias notas" unless last_note.deletable_by?(user)
    
    last_note.destroy!
    Rails.logger.info "🗑️  Nota eliminada de documento #{@document.id} por #{user.email}"
  rescue StandardError => e
    Rails.logger.error "❌ Error eliminando nota: #{e.message}"
    raise
  end

  # Verificar y marcar expirados automáticamente
  def self.check_and_mark_expired!
    DocumentSubmission
      .where(validation_status: 'approved')
      .where("expiry_date < ?", Date.current)
      .find_each do |doc|
        service = new(doc)
        service.mark_expired!(User.system, "Auto-expiración por vigencia vencida")
      end
  end

  private

  # Método privado para agregar notas del sistema
  private

  def add_system_note(user, content, note_type)
    return if content.blank?
    
    @document.document_notes.create!(
      user: user,
      content: content,
      note_type: note_type
    )
  end

  def transaction
    ActiveRecord::Base.transaction { yield }
  end
end
