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


  # POST /business_transactions/:business_transaction_id/document_submissions/:id/upload
  def upload
    if params[:document_file].present?
      @document_submission.document_file.attach(params[:document_file])
      @document_submission.update!(
        submitted_at: Time.current,
        uploaded_by: current_user,
        document_status: DocumentStatus.find_by(name: 'pendiente_validacion')
      )
      
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  notice: 'Documento cargado exitosamente. Se está analizando...'
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'Debe seleccionar un archivo'
    end
  end

  # POST /business_transactions/:business_transaction_id/document_submissions/:id/validate
  def validate_document
    authorize_validation!
    
    @document_submission.update!(
      document_status: DocumentStatus.find_by(name: 'validado'),
      validated_by: current_user,
      validated_at: Time.current,
      validation_notes: params[:validation_notes]
    )
    
    redirect_to business_transaction_document_submissions_path(@business_transaction),
                notice: 'Documento validado correctamente'
  end

  # POST /business_transactions/:business_transaction_id/document_submissions/:id/reject
  def reject_document
    authorize_validation!
    
    @document_submission.update!(
      document_status: DocumentStatus.find_by(name: 'rechazado'),
      validated_by: current_user,
      validated_at: Time.current,
      validation_notes: params[:rejection_reason]
    )
    
    redirect_to business_transaction_document_submissions_path(@business_transaction),
                alert: 'Documento rechazado'
  end

  # GET /business_transactions/:business_transaction_id/document_submissions/:id/download
  def download
    if @document_submission.document_file.attached?
      redirect_to rails_blob_path(@document_submission.document_file, disposition: 'attachment')
    else
      redirect_to business_transaction_document_submissions_path(@business_transaction),
                  alert: 'No hay archivo adjunto'
    end
  end

  # DELETE /business_transactions/:business_transaction_id/document_submissions/:id
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

  private

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
