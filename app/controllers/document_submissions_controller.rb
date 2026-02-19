# app/controllers/document_submissions_controller.rb
# 🔥 SOLO document_status - SIN validation_status ENUM


class DocumentSubmissionsController < ApplicationController
  include Pundit::Authorization


  before_action :authenticate_user!
  before_action :set_business_transaction
  before_action :set_document_submission, only: [
    :show, :upload, :validate, :reject, :mark_expired,
    :add_note, :delete_note, :download, :destroy, :preview
  ]


  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized


  # ===========================================================================
  # INDEX: Listar documentos con checklist
  # ===========================================================================
  def index
    @checklist = DocumentChecklistService.new(@business_transaction).checklist


    respond_to do |format|
      format.html
      format.json { render json: @checklist }
    end
  end


  # ===========================================================================
  # SHOW: Ver detalles de un documento
  # ===========================================================================
  def show
    respond_to do |format|
      format.html
      format.json { render json: @document_submission.as_json(include: :document_type) }
    end
  end


  # ===========================================================================
  # PREVIEW: Ver preview del documento en modal
  # ===========================================================================
  def preview
    @document_submission = DocumentSubmission.find(params[:id])
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])


    respond_to do |format|
      format.html { render layout: false }
      format.json do
        render json: {
          id: @document_submission.id,
          document_type: @document_submission.document_type.name,
          status: @document_submission.document_status&.name,
          uploaded_at: @document_submission.submitted_at&.strftime('%d/%m/%Y %H:%M'),
          uploaded_by: @document_submission.uploaded_by&.email,
          file_url: @document_submission.document_file.attached? ?
                    url_for(@document_submission.document_file) : nil,
          content_type: @document_submission.document_file.content_type,
          analysis: {
            status: @document_submission.analysis_status,
            legibility_score: @document_submission.legibility_score
          }
        }
      end
    end
  end


  # ===========================================================================
  # UPLOAD: Cargar/reemplazar archivo de documento
  # ===========================================================================
  def upload
    if params[:document_file].present?
      @document_submission.document_file.attach(params[:document_file])
      @document_submission.update!(
        submitted_at: Time.current,
        uploaded_by: current_user,
        document_status: DocumentStatus.find_by(name: 'recibido_revision')
      )
      DocumentAnalysisJob.perform_later(@document_submission.id)


      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  notice: 'Documento cargado exitosamente. Se está analizando...'
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'Debe seleccionar un archivo'
    end
  end

  # ============================================================================
  # VALIDATE - Método CORREGIDO con nombres de status reales
  # ============================================================================
  def validate
    @document_submission = DocumentSubmission.find(params[:id])
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])

    authorize @document_submission, :validate?

    # Variables para Turbo Stream
    @validation_notes = params[:notes].presence
    @current_user = current_user

    # ✅ SOLO ACTUALIZA document_status - USANDO "validado_vigente"
    if @document_submission.update(
      document_status: DocumentStatus.find_by(name: 'validado_vigente'),
      validated_at: Time.current,
      validated_by_id: current_user.id
    )
      @document_submission.document_notes.create(
        user: current_user,
        content: @validation_notes || "Documento validado",
        note_type: 'status_change'
      )

      # 🔥 RECALCULAR CONTADORES
      @validated_count = @business_transaction.document_submissions.where(
        document_status: DocumentStatus.find_by(name: 'validado_vigente')
      ).count



      respond_to do |format|
        format.turbo_stream { render :validate }
        format.html do
          redirect_to business_transaction_document_submissions_path(@business_transaction),
            notice: "✅ Documento validado"
        end
      end
    else
      # ERROR CASE
      @error_message = @document_submission.errors.full_messages.join(", ")
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_entity }
        format.html do
          redirect_to preview_business_transaction_document_submission_path(
            @business_transaction, @document_submission
          ), alert: "Error al validar: #{@error_message}"
        end
      end
    end
  rescue StandardError => e
    redirect_to preview_business_transaction_document_submission_path(
      @business_transaction, @document_submission
    ), alert: "Error: #{e.message}"
  end


  # ============================================================================
  # REJECT - Método CORREGIDO con nombres de status reales
  # ============================================================================
  def reject
    @document_submission = DocumentSubmission.find(params[:id])
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])

    authorize @document_submission, :reject?

    @rejection_reason = params[:reason].presence
    @current_user = current_user

    if @rejection_reason.blank?
      @error_message = "Motivo de rechazo requerido"
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_entity }
        format.html do
          redirect_to preview_business_transaction_document_submission_path(
            @business_transaction, @document_submission
          ), alert: @error_message
        end
      end
      return
    end

    # ✅ SOLO ACTUALIZA document_status - USANDO "rechazado"
    if @document_submission.update(
      document_status: DocumentStatus.find_by(name: 'rechazado'),
      validated_at: Time.current,
      validated_by_id: current_user.id
    )
      @document_submission.document_notes.create(
        user: current_user,
        content: "Documento rechazado: #{@rejection_reason}",
        note_type: 'status_change'
      )

      # 🔥 RECALCULAR CONTADORES
      @rejected_count = @business_transaction.document_submissions.where(
        document_status: DocumentStatus.find_by(name: 'rechazado')
      ).count


      respond_to do |format|
        format.turbo_stream { render :reject }
        format.html do
          redirect_to business_transaction_document_submissions_path(@business_transaction),
            notice: "❌ Documento rechazado"
        end
      end
    else
      # ERROR CASE
      @error_message = @document_submission.errors.full_messages.join(", ")
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_entity }
        format.html do
          redirect_to preview_business_transaction_document_submission_path(
            @business_transaction, @document_submission
          ), alert: "Error al rechazar: #{@error_message}"
        end
      end
    end
  rescue StandardError => e
    redirect_to preview_business_transaction_document_submission_path(
      @business_transaction, @document_submission
    ), alert: "Error: #{e.message}"
  end


  # ============================================================================
  # MARK_EXPIRED - Método CORREGIDO con nombres de status reales
  # ============================================================================
  def mark_expired
    @document_submission = DocumentSubmission.find(params[:id])
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])

    authorize @document_submission, :mark_expired?

    @expiration_reason = params[:reason].presence
    @current_user = current_user

    if @expiration_reason.blank?
      @error_message = "Motivo de expiración requerido"
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_entity }
        format.html do
          redirect_to preview_business_transaction_document_submission_path(
            @business_transaction, @document_submission
          ), alert: @error_message
        end
      end
      return
    end
    # ✅ SOLO ACTUALIZA document_status - USANDO "vencido"
    if @document_submission.update(
      document_status: DocumentStatus.find_by(name: 'vencido'),
      validated_at: Time.current,
      validated_by_id: current_user.id
    )
      @document_submission.document_notes.create(
        user: current_user,
        content: "Documento marcado como vencido: #{@expiration_reason}",
        note_type: 'status_change'
      )

      # 🔥 RECALCULAR CONTADORES
      @expired_count = @business_transaction.document_submissions.where(
        document_status: DocumentStatus.find_by(name: 'vencido')
      ).count
      
      respond_to do |format|
        format.turbo_stream { render :mark_expired }
        format.html do
          redirect_to business_transaction_document_submissions_path(@business_transaction),
            notice: "⏰ Documento marcado como vencido"
        end
      end
    else
      # ERROR CASE
      @error_message = @document_submission.errors.full_messages.join(", ")
      respond_to do |format|
        format.turbo_stream { render :error, status: :unprocessable_entity }
        format.html do
          redirect_to preview_business_transaction_document_submission_path(
            @business_transaction, @document_submission
          ), alert: "Error al marcar como vencido: #{@error_message}"
        end
      end
    end
  rescue StandardError => e
    redirect_to preview_business_transaction_document_submission_path(
      @business_transaction, @document_submission
    ), alert: "Error: #{e.message}"
  end
  


  # ===========================================================================
  # ADD_NOTE: Agregar nota/comentario
  # ===========================================================================
  def add_note
    @document_submission = DocumentSubmission.find(params[:id])
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])


    authorize @document_submission, :add_note?


    @note = @document_submission.document_notes.build(note_params)
    @note.user = current_user


    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to business_transaction_document_submission_path(@business_transaction, @document_submission), notice: "Nota agregada" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :add_note_error, status: :unprocessable_entity }
        format.html { redirect_to preview_business_transaction_document_submission_path(@business_transaction, @document_submission), alert: "Error al agregar nota" }
      end
    end
  rescue Pundit::NotAuthorizedError
    redirect_to business_transaction_document_submissions_path(@business_transaction), alert: "No tienes permiso"
  end


  # ===========================================================================
  # DELETE_NOTE: Eliminar nota
  # ===========================================================================
  def delete_note
    @note = DocumentNote.find(params[:id])
    @submission = @note.document_submission
    authorize @submission, :delete_note?


    begin
      @note.destroy


      respond_to do |format|
        format.json { render json: { success: true } }
        format.turbo_stream { render :update_notes }
      end
    rescue StandardError => e
      handle_error(e, :delete_note)
    end
  end


  # ===========================================================================
  # DOWNLOAD: Descargar archivo del documento
  # ===========================================================================
  def download
    if @document_submission.document_file.attached?
      redirect_to rails_blob_path(@document_submission.document_file, disposition: 'attachment')
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'No hay archivo adjunto'
    end
  end


  # ===========================================================================
  # DESTROY: Eliminar documento y archivo
  # ===========================================================================
  def destroy
    authorize @document_submission, :destroy?


    @document_submission.document_file.purge if @document_submission.document_file.attached?
    @document_submission.update!(
      submitted_at: nil,
      uploaded_by: nil,
      document_status: DocumentStatus.find_by(name: 'pendiente_solicitud')
    )


    respond_to do |format|
      format.html do
        redirect_to business_transaction_document_submissions_path(@business_transaction),
                    notice: '🗑️ Documento eliminado'
      end
      format.json { render json: { success: true } }
    end
  end


  # ===========================================================================
  # EXPORT_CHECKLIST: Exportar checklist en PDF, Excel o TXT
  # ===========================================================================
  def export_checklist
    @checklist = DocumentChecklistService.new(@business_transaction).checklist


    respond_to do |format|
      format.html { render layout: false }


      format.pdf do
        pdf = Prawn::Document.new(page_size: 'A4', margin: [20, 20, 20, 20])


        pdf.font_families.update(
          'DejaVuSans' => {
            normal: '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
            bold: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
            italic: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf'
          }
        )
        pdf.font 'DejaVuSans'


        render_checklist_pdf(pdf)


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


  # ===========================================================================
  # PRIVATE: Métodos auxiliares
  # ===========================================================================
  private


  def note_params
    params.permit(:content, :note_type)
  end


  def set_business_transaction
    @business_transaction = BusinessTransaction.find(params[:business_transaction_id])
  end


  def set_document_submission
    @document_submission = @business_transaction.document_submissions.find(params[:id])
  end


  def handle_error(error, action)
    error_message = "❌ Error en #{action}: #{error.message}"


    respond_to do |format|
      format.turbo_stream { render :error, locals: { error: error_message } }
      format.html do
        redirect_to business_transaction_document_submissions_path(@business_transaction),
                    alert: error_message
      end
      format.json { render json: { error: error_message }, status: :unprocessable_entity }
    end
  end


  def user_not_authorized
    flash[:alert] = "No tiene permiso para realizar esta acción"
    redirect_to(request.referrer || business_transaction_document_submissions_path(@business_transaction))
  end


  def render_checklist_pdf(pdf)
    pdf.text "CHECKLIST DOCUMENTAL", size: 18, style: :bold
    pdf.move_down 10


    pdf.text "Transacción: ##{@business_transaction.id}", size: 11
    pdf.text "Propiedad: #{@business_transaction.property.address}", size: 11
    pdf.text "Escenario: #{@business_transaction.transaction_scenario&.name || 'Sin escenario'}", size: 11
    pdf.text "Fecha: #{I18n.l(Date.today, format: :long)}", size: 11
    pdf.move_down 15


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
    pdf.text "DETALLE POR PERSONA", size: 14, style: :bold
    pdf.move_down 8

    copros = @checklist[:copropietarios] || @checklist["copropietarios"] || []

    if copros.empty?
      pdf.text "No hay copropietarios registrados.", size: 10
      return
    end

    copros.each do |co|
      co_owner   = co[:co_owner]   || co["co_owner"]   || {}
      documents  = co[:documents]  || co["documents"]  || {}
      doc_lists  = documents[:list] || documents["list"] || []

      total_docs = doc_lists.sum { |cat| (cat[:documents] || cat["documents"] || []).size }

      name       = co_owner[:name]       || co_owner["name"]       || "Copropietario"
      role       = co_owner[:role]       || co_owner["role"]       || "Rol"
      percentage = co_owner[:percentage] || co_owner["percentage"] || 0

      pdf.text "#{name} (#{role} - #{percentage}%)", size: 12, style: :bold
      pdf.text "Documentos requeridos: #{total_docs}", size: 10
      pdf.move_down 4

      doc_lists.each do |category|
        docs = category[:documents] || category["documents"] || []
        next if docs.empty?

        cat_name = category[:category] || category["category"] || "Categoría"
        pdf.text "• #{cat_name} (#{docs.size})", size: 11, style: :bold

        docs.each do |doc|
          submission = doc[:submission] || doc["submission"]

          attached = submission.respond_to?(:document_file) && submission.document_file.attached?
          status_icon = attached ? "✅" : "☐"

          raw_doc_type = doc[:document_type] || doc["document_type"]
          doc_name =
            if raw_doc_type.respond_to?(:name)
              raw_doc_type.name
            elsif raw_doc_type.is_a?(Hash)
              raw_doc_type[:name] || raw_doc_type["name"] || "Documento"
            else
              "Documento"
            end

          raw_status =
            if submission.respond_to?(:document_status)
              submission.document_status&.name
            elsif submission.is_a?(Hash)
              submission[:document_status_name] ||
              submission["document_status_name"] ||
              (submission.dig(:document_status, :name) rescue nil) ||
              (submission.dig("document_status", "name") rescue nil)
            end

          raw_status ||= (attached ? "cargado" : "pendiente")
          status_text = raw_status.to_s.tr("_", " ").capitalize

          pdf.text "   #{status_icon} #{doc_name} [#{status_text}]", size: 10
        end

        pdf.move_down 4
      end

      pdf.move_down 8
    end
  end

  
  def generate_checklist_text
    checklist = @checklist

    output = "📋 CHECKLIST DOCUMENTAL\n"
    output << "═" * 40 << "\n\n"

    output << "Transacción: ##{@business_transaction.id}\n"
    output << "Propiedad: #{@business_transaction.property.address}\n"
    output << "Escenario: #{@business_transaction.transaction_scenario&.name || 'Sin escenario'}\n"
    output << "Fecha: #{I18n.l(Date.today, format: :long)}\n\n"

    # Resumen
    summary = checklist[:summary] || checklist["summary"] || {}
    output << "📊 RESUMEN\n"
    output << "─" * 40 << "\n"
    output << "Total: #{summary[:total] || summary['total']} | "
    output << "Cargados: #{summary[:uploaded] || summary['uploaded']} | "
    output << "Validados: #{summary[:validated] || summary['validated']} | "
    output << "Rechazados: #{summary[:rejected] || summary['rejected']} | "
    output << "Progreso: #{summary[:progress] || summary['progress']}%\n\n"

    output << "👤 PERSONAS\n"
    output << "═" * 40 << "\n\n"

    copros = checklist[:copropietarios] || checklist["copropietarios"] || []

    if copros.empty?
      output << "No hay copropietarios registrados.\n"
      return output
    end

    copros.each do |co|
      co_owner   = co[:co_owner]   || co["co_owner"]   || {}
      documents  = co[:documents]  || co["documents"]  || {}
      doc_lists  = documents[:list] || documents["list"] || []

      total_docs = doc_lists.sum { |cat| (cat[:documents] || cat["documents"] || []).size }

      name       = co_owner[:name]       || co_owner["name"]       || "Copropietario"
      role       = co_owner[:role]       || co_owner["role"]       || "Rol"
      percentage = co_owner[:percentage] || co_owner["percentage"] || 0

      output << "👨 #{name}\n"
      output << "   (#{role} - #{percentage}%)\n"
      output << "   Documentos requeridos: #{total_docs}\n"
      output << "─" * 40 << "\n\n"

      doc_lists.each do |category|
        docs = category[:documents] || category["documents"] || []
        next if docs.empty?

        cat_name = category[:category] || category["category"] || "Categoría"
        output << "📍 #{cat_name} (#{docs.size})\n"

        docs.each do |doc|
          submission = doc[:submission] || doc["submission"]

          # 1) archivo adjunto
          attached = submission.respond_to?(:document_file) && submission.document_file.attached?
          status_icon = attached ? "✅" : "☐"

          # 2) tipo de documento (modelo o hash)
          raw_doc_type = doc[:document_type] || doc["document_type"]

          doc_name =
            if raw_doc_type.respond_to?(:name)
              raw_doc_type.name
            elsif raw_doc_type.is_a?(Hash)
              raw_doc_type[:name] || raw_doc_type["name"] || "Documento"
            else
              "Documento"
            end

          # 3) status textual (modelo o hash)
          raw_status =
            if submission.respond_to?(:document_status)
              submission.document_status&.name
            elsif submission.is_a?(Hash)
              submission[:document_status_name] ||
              submission["document_status_name"] ||
              submission.dig(:document_status, :name) rescue nil ||
              submission.dig("document_status", "name") rescue nil
            end

          raw_status ||= (attached ? "cargado" : "pendiente")
          status_text = raw_status.to_s.tr("_", " ").capitalize

          output << "   #{status_icon} #{doc_name} [#{status_text}]\n"
        end



        output << "\n"
      end

      output << "\n"
    end

    output
  end

end
