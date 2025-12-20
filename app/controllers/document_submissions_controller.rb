# app/controllers/document_submissions_controller.rb
class DocumentSubmissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_business_transaction
  before_action :set_document_submission, only: [:show, :upload, :validate_document, :reject_document, :download, :destroy, :preview]

  # GET /business_transactions/:business_transaction_id/document_submissions
  def index
    @checklist = DocumentChecklistService.new(@business_transaction).checklist
    
    respond_to do |format|
      format.html
      format.json { render json: @checklist }
    end
  end

  # GET /business_transactions/:business_transaction_id/document_submissions/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @document_submission.as_json(include: :document_type) }
    end
  end


  def approve
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission, :approve?
    
    notes = params[:notes].presence
    
    begin
      service = DocumentValidationService.new(@submission)
      service.approve!(current_user, notes)
      
      respond_to do |format|
        format.turbo_stream { render :update_submission }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), notice: '✅ Documento aprobado' }
      end
    rescue StandardError => e
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error: e.message } }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), alert: "❌ Error: #{e.message}" }
      end
    end
  end

  def reject
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission
    
    reason = params[:reason]
    raise "Motivo requerido" if reason.blank?
    
    begin
      service = DocumentValidationService.new(@submission)
      service.reject!(current_user, reason)
      
      respond_to do |format|
        format.turbo_stream { render :update_submission }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), notice: '❌ Documento rechazado - pedir re-subida' }
      end
    rescue StandardError => e
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error: e.message } }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), alert: "❌ Error: #{e.message}" }
      end
    end
  end

  def mark_expired
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission
    
    reason = params[:reason].presence || "Vigencia vencida"
    
    begin
      service = DocumentValidationService.new(@submission)
      service.mark_expired!(current_user, reason)
      
      respond_to do |format|
        format.turbo_stream { render :update_submission }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), notice: '⏰ Documento marcado como expirado' }
      end
    rescue StandardError => e
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error: e.message } }
        format.html { redirect_to business_transaction_document_submissions_path(@submission.business_transaction), alert: "❌ Error: #{e.message}" }
      end
    end
  end


  def add_note
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission
    
    content = params[:content]
    raise "Contenido requerido" if content.blank?
    
    begin
      service = DocumentValidationService.new(@submission)
      @note = service.add_note(current_user, content)
      
      respond_to do |format|
        format.json { render json: @note, status: :created }
        # 🔴 QUITAMOS format.turbo_stream
      end
    rescue StandardError => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end


  def add_note_anterior
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission
    
    content = params[:content]
    raise "Contenido requerido" if content.blank?
    
    begin
      service = DocumentValidationService.new(@submission)
      @note = service.add_note(current_user, content)
      
      respond_to do |format|
        format.turbo_stream { render :update_notes }
        format.json { render json: @note, status: :created }
      end
    rescue StandardError => e
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error: e.message } }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  
  def delete_note
    @note = DocumentNote.find(params[:id])
    @submission = @note.document_submission
    authorize @submission
    
    begin
      service = DocumentValidationService.new(@submission)
      service.delete_last_note(current_user)
      
      respond_to do |format|
        format.json { render json: { success: true }, status: :ok }
        # 🔴 QUITAMOS format.turbo_stream
      end
    rescue StandardError => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end


  def delete_note_anterior
    @note = DocumentNote.find(params[:id])
    @submission = @note.document_submission
    authorize @submission
    
    begin
      service = DocumentValidationService.new(@submission)
      service.delete_last_note(current_user)
      
      respond_to do |format|
        format.turbo_stream { render :update_notes }
        format.json { render json: { success: true }, status: :ok }
      end
    rescue StandardError => e
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error: e.message } }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  # AGREGAR en las rutas privadas (al final del archivo):

  def authorize_submission
    @submission = DocumentSubmission.find(params[:id])
    authorize @submission
  end






  def preview
    @submission = @document_submission
    
    respond_to do |format|
      format.html { render layout: false } # Sin layout para modal
      format.json do
        render json: {
          id: @submission.id,
          document_type: @submission.document_type.name,
          status: @submission.document_status&.name,
          uploaded_at: @submission.submitted_at&.strftime('%d/%m/%Y %H:%M'),
          uploaded_by: @submission.uploaded_by&.email,
          file_url: @submission.document_file.attached? ? url_for(@submission.document_file) : nil,
          content_type: @submission.document_file.content_type,
          analysis: {
            status: @submission.analysis_status,
            legibility_score: @submission.legibility_score,
            ocr_text: @submission.ocr_text,
            auto_validated: @submission.auto_validated
          }
        }
      end
    end
  end


  def upload
    if params[:document_file].present?
      @document_submission.document_file.attach(params[:document_file])
      @document_submission.update!(
        submitted_at: Time.current,
        uploaded_by: current_user,
        document_status: DocumentStatus.find_by(name: 'pendiente_validacion')
      )
      DocumentAnalysisJob.perform_later(@document_submission.id)

      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  notice: 'Documento cargado exitosamente. Se está analizando...'
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'Debe seleccionar un archivo'
    end
  end

  def validate_document
    authorize_validation!
    
    @document_submission.update!(
      document_status: DocumentStatus.find_by(name: 'validado'),
      validated_by: current_user,
      validated_at: Time.current,
      validation_notes: params[:validation_notes]
    )
    
    # Agregar nota
    DocumentNote.create!(
      document_submission: @document_submission,
      user: current_user,
      content: params[:validation_notes].presence || 'Documento aprobado',
      note_type: 'acceptance'
    )



    redirect_to business_transaction_document_submissions_path(@business_transaction),
                notice: 'Documento validado correctamente'
  end

  def reject_document
    authorize_validation!
    
    @document_submission.update!(
      document_status: DocumentStatus.find_by(name: 'rechazado'),
      validated_by: current_user,
      validated_at: Time.current,
      validation_notes: params[:rejection_reason]
    )
    
    # Agregar nota con el motivo
    DocumentNote.create!(
      document_submission: @document_submission,
      user: current_user,
      content: params[:rejection_reason],
      note_type: 'rejection'
    )
    


    redirect_to business_transaction_document_submissions_path(@business_transaction),
                alert: 'Documento rechazado'
  end

  def download
    if @document_submission.document_file.attached?
      redirect_to rails_blob_path(@document_submission.document_file, disposition: 'attachment')
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'No hay archivo adjunto'
    end
  end

  def destroy
    authorize_deletion!
    
    @document_submission.document_file.purge if @document_submission.document_file.attached?
    @document_submission.update!(
      submitted_at: nil,
      uploaded_by: nil,
      document_status: DocumentStatus.find_by(name: 'pendiente_solicitud')
    )
    
    redirect_to business_transaction_document_submissions_path(@business_transaction),
                notice: 'Documento eliminado'
  end

  
  def export_checklist
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])
    @checklist = DocumentChecklistService.new(@business_transaction).checklist

    respond_to do |format|
      format.html { render layout: false }
      
      format.pdf do
        pdf = Prawn::Document.new(page_size: 'A4', margin: [20, 20, 20, 20])
        
        # Define la fuente que soporta UTF-8
        pdf.font_families.update(
          'DejaVuSans' => {
            normal: '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
            bold: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
            italic: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf'
          }
        )
        pdf.font 'DejaVuSans'
        
        # Título
        pdf.text "CHECKLIST DOCUMENTAL", size: 18, style: :bold
        pdf.move_down 10
        
        # Encabezado
        pdf.text "Transacción: ##{@business_transaction.id}", size: 11
        pdf.text "Propiedad: #{@business_transaction.property.address}", size: 11
        pdf.text "Escenario: #{@business_transaction.transaction_scenario&.name || 'Sin escenario'}", size: 11
        pdf.text "Fecha: #{I18n.l(Date.today, format: :long)}", size: 11
        pdf.move_down 15
        
        # Resumen
        pdf.text "RESUMEN GENERAL", size: 14, style: :bold
        pdf.move_down 8
        
        summary_data = [
          ["Total", "Cargados", "Pendientes", "Validados", "Rechazados", "Progreso"],
          [
            @checklist[:summary][:total].to_s,
            @checklist[:summary][:uploaded].to_s,
            @checklist[:summary][:pending].to_s,
            @checklist[:summary][:validated].to_s,
            @checklist[:summary][:rejected].to_s,
            "#{@checklist[:summary][:progress]}%"
          ]
        ]
        
        pdf.table(summary_data, width: pdf.bounds.width, cell_style: { size: 10, padding: 5 }) do |t|
          t.header = true
        end
        
        pdf.move_down 15
        
        # Documentos por copropietario
        pdf.text "DOCUMENTOS POR COPROPIETARIO", size: 14, style: :bold
        pdf.move_down 8
        
        co_owner_data = [["Copropietario", "Rol", "%", "Total", "Cargados", "Pendientes"]]
        
        @checklist[:copropietarios].each do |co_data|
          co_owner_data << [
            co_data[:co_owner][:name],
            co_data[:co_owner][:role].titleize,
            "#{co_data[:co_owner][:percentage]}%",
            co_data[:documents][:total].to_s,
            co_data[:documents][:uploaded].to_s,
            (co_data[:documents][:total] - co_data[:documents][:uploaded]).to_s
          ]
        end
        
        pdf.table(co_owner_data, width: pdf.bounds.width, cell_style: { size: 9, padding: 4 }) do |t|
          t.header = true
        end
        
        pdf.move_down 15
        
        # Detalle de documentos
        pdf.text "DETALLE DE DOCUMENTOS", size: 14, style: :bold
        pdf.move_down 10
        
        @checklist[:copropietarios].each do |co_data|
          pdf.text "#{co_data[:co_owner][:name]} (#{co_data[:co_owner][:percentage]}%)", size: 12, style: :bold
          pdf.move_down 5
          
          co_data[:documents][:list].each do |category|
            pdf.text "#{category[:category_display]}", size: 11, style: :italic
            pdf.move_down 3
            
            category[:documents].each do |doc|
              status = doc[:uploaded] ? "[X]" : "[ ]"
              pdf.text "   #{status} #{doc[:document_type][:name]}", size: 10
            end
            
            pdf.move_down 5
          end
          
          pdf.move_down 10
        end
        
        send_data pdf.render, 
                  filename: "checklist_#{@business_transaction.id}.pdf",
                  type: 'application/pdf',
                  disposition: 'attachment'
      end
      
      format.text do
        text_content = generate_checklist_text
        send_data text_content,
                  filename: "checklist_#{@business_transaction.id}.txt",
                  type: 'text/plain',
                  disposition: 'attachment'
      end
    end
  end

  private

  def generate_checklist_text
    output = "CHECKLIST DOCUMENTAL\n"
    output += "═" * 60 + "\n\n"
    
    output += "Transacción: ##{@business_transaction.id}\n"
    output += "Propiedad: #{@business_transaction.property.address}\n"
    output += "Escenario: #{@business_transaction.transaction_scenario&.name || 'Sin escenario'}\n"
    output += "Fecha: #{I18n.l(Date.today, format: :long)}\n\n"
    
    output += "RESUMEN\n"
    output += "─" * 60 + "\n"
    output += "Total de documentos: #{@checklist[:summary][:total]}\n"
    output += "Cargados: #{@checklist[:summary][:uploaded]}\n"
    output += "Pendientes: #{@checklist[:summary][:pending]}\n"
    output += "Validados: #{@checklist[:summary][:validated]}\n"
    output += "Rechazados: #{@checklist[:summary][:rejected]}\n"
    output += "Progreso: #{@checklist[:summary][:progress]}%\n\n"
    
    @checklist[:copropietarios].each do |co_data|
      output += "#{co_data[:co_owner][:name]}\n"
      output += "   Rol: #{co_data[:co_owner][:role].titleize}\n"
      output += "   Porcentaje: #{co_data[:co_owner][:percentage]}%\n"
      output += "   Documentos: #{co_data[:documents][:total]} | Cargados: #{co_data[:documents][:uploaded]} | Pendientes: #{co_data[:documents][:total] - co_data[:documents][:uploaded]}\n"
      output += "   " + ("─" * 50) + "\n\n"
      
      co_data[:documents][:list].each do |category|
        output += "   #{category[:category_display]}\n"
        category[:documents].each do |doc|
          status = doc[:uploaded] ? "✅" : "☐"
          output += "       #{status} #{doc[:document_type][:name]}\n"
        end
        output += "\n"
      end
    end
    
    output
  end



  def document_submission_params
    # params.require(:document_submission).permit(:document_type_id)
    { document_file: params[:file] }

  end


  def set_business_transaction
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])
  end

  def set_document_submission
    @document_submission = @business_transaction.document_submissions.find(params[:id])
  end

  def authorize_validation!
    unless current_user.admin? || current_user.agent?
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'No tiene permisos para validar documentos' and return
    end
  end

  def authorize_deletion!
    unless current_user.admin? || @document_submission.uploaded_by == current_user
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'No tiene permisos para eliminar este documento' and return
    end
  end
end
