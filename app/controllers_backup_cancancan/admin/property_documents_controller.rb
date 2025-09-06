# app/controllers/admin/property_documents_controller.rb
class Admin::PropertyDocumentsController < Admin::BaseController
  before_action :set_doc, only: [:show, :destroy]

  def index
    @documents = PropertyDocument.includes(:property, :document_type, :user)
  end

  def show
  end

  def destroy
    @doc.destroy
    redirect_to admin_property_documents_path, notice: 'Documento eliminado.'
  end

  private

  def set_doc
    @doc = PropertyDocument.find(params[:id])
  end
end
