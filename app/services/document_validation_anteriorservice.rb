# app/services/document_validation_service.rb
class DocumentValidationService
  attr_reader :submission

  def initialize(submission)
    @submission = submission
  end

  # Validar/Aprobar documento
  def validate!(user, notes = nil)
    ActiveRecord::Base.transaction do
      @submission.update!(
        document_status: DocumentStatus.find_by(name: 'validado'),
        validated_by: user,
        validated_at: Time.current,
        validation_notes: notes
      )
      
      note_content = notes.presence || '✅ Documento aprobado'
      create_note(user, note_content, 'status_change')
    end
  end

  # Rechazar documento
  def reject!(user, reason)
    raise "Motivo de rechazo requerido" if reason.blank?
    
    ActiveRecord::Base.transaction do
      @submission.update!(
        document_status: DocumentStatus.find_by(name: 'rechazado'),
        validated_by: user,
        validated_at: Time.current,
        validation_notes: reason
      )
      
      create_note(user, reason, 'rejection')
    end
  end

  # Marcar como expirado
  def mark_expired!(user, reason = 'Vigencia vencida')
    ActiveRecord::Base.transaction do
      @submission.update!(
        document_status: DocumentStatus.find_by(name: 'expirado'),
        validated_by: user,
        validated_at: Time.current,
        validation_notes: reason
      )
      
      create_note(user, "⏰ #{reason}", 'status_change')
    end
  end

  # Agregar nota manual
  def add_note(user, content, note_type = 'comment')
    raise "Contenido requerido" if content.blank?
    create_note(user, content, note_type)
  end

  # Eliminar nota
  def delete_note(user, note)
    unless user == note.user || user.admin?
      raise "No tiene permisos para eliminar esta nota"
    end
    
    note.destroy!
  end

  # Alias para compatibilidad
  def approve!(user, notes = nil)
    validate!(user, notes)
  end

  private

  def create_note(user, content, note_type)
    DocumentNote.create!(
      document_submission: @submission,
      user: user,
      content: content,
      note_type: note_type
    )
  end
end
