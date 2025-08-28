# app/controllers/admin/document_types_controller.rb
class Admin::DocumentTypesController < Admin::BaseController
  before_action :set_document_type, only: [:show, :edit, :update, :destroy]

  def index
    @document_types = DocumentType.order(:name)
  end

  def show
  end

  def new
    @document_type = DocumentType.new(valid_from: Date.current, is_active: true)
  end

  def create
    @document_type = DocumentType.new(document_type_params)
    if @document_type.save
      redirect_to admin_document_type_path(@document_type), notice: 'Tipo de documento creado.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @document_type.update(document_type_params)
      redirect_to admin_document_type_path(@document_type), notice: 'Tipo de documento actualizado.'
    else
      render :edit
    end
  end

  def destroy
    @document_type.destroy
    redirect_to admin_document_types_path, notice: 'Tipo de documento eliminado.'
  end

  private

  def set_document_type
    @document_type = DocumentType.find(params[:id])
  end

  def document_type_params
    params.require(:document_type).permit(
      :name, :description, :category,
      :valid_from, :valid_until,
      :replacement_document_id,
      :is_active
    )
  end
end