class Admin::DocumentTypesController < Admin::BaseController
  before_action :authenticate_user!

  def index
    @document_types = policy_scope(DocumentType)
    authorize DocumentType
  end

  def show
    @document_type = DocumentType.find(params[:id])
    authorize @document_type
  end

  def new
    @document_type = DocumentType.new
    authorize @document_type
  end

  def create
    @document_type = DocumentType.new(document_type_params)
    authorize @document_type

    if @document_type.save
      redirect_to admin_document_types_path, notice: "Tipo de documento creado exitosamente."
    else
      render :new
    end
  end

  def edit
    @document_type = DocumentType.find(params[:id])
    authorize @document_type
  end

  def update
    @document_type = DocumentType.find(params[:id])
    authorize @document_type

    if @document_type.update(document_type_params)
      redirect_to admin_document_types_path, notice: "Tipo de documento actualizado exitosamente."
    else
      render :edit
    end
  end

  def destroy
    @document_type = DocumentType.find(params[:id])
    authorize @document_type
    @document_type.destroy
    redirect_to admin_document_types_path, notice: "Tipo de documento eliminado exitosamente."
  end

  private

  def document_type_params
    params.require(:document_type).permit(:name, :description, :category, :valid_from, :valid_until, :is_active)
  end
end
