class Admin::DocumentTypesController < ApplicationController
  # ✅ CAMBIAR: De ensure_admin a ensure_admin_or_superadmin
  before_action :ensure_admin_or_superadmin
  
  def index
    @document_types = DocumentType.all
  end
  
  def show
    @document_type = DocumentType.find(params[:id])
  end
  
  def new
    @document_type = DocumentType.new
  end
  
  def create
    @document_type = DocumentType.new(document_type_params)
    
    if @document_type.save
      redirect_to admin_document_types_path, notice: 'Tipo de documento creado exitosamente.'
    else
      render :new
    end
  end
  
  def edit
    @document_type = DocumentType.find(params[:id])
  end
  
  def update
    @document_type = DocumentType.find(params[:id])
    
    if @document_type.update(document_type_params)
      redirect_to admin_document_types_path, notice: 'Tipo de documento actualizado exitosamente.'
    else
      render :edit
    end
  end
  
  def destroy
    @document_type = DocumentType.find(params[:id])
    @document_type.destroy
    redirect_to admin_document_types_path, notice: 'Tipo de documento eliminado exitosamente.'
  end
  
  private
  
  def document_type_params
    params.require(:document_type).permit(:name, :description, :category, :valid_from, :valid_until, :is_active)
  end
  
  # ✅ AGREGAR: Método de autorización correcto
  def ensure_admin_or_superadmin
    unless current_user&.admin_or_above?
      redirect_to root_path, alert: "Acceso denegado"
    end
  end
end
