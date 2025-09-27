# app/controllers/admin/document_requirements_controller.rb
class Admin::DocumentRequirementsController < Admin::BaseController
  before_action :set_requirement, only: [ :show, :edit, :update, :destroy ]

  def index
    @requirements = DocumentRequirement.includes(:document_type).order(:property_type)
  end

  def show
  end

  def new
    @requirement = DocumentRequirement.new(valid_from: Date.current, is_required: true)
  end

  def create
    @requirement = DocumentRequirement.new(requirement_params)
    if @requirement.save
      redirect_to admin_document_requirement_path(@requirement), notice: "Requisito creado."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @requirement.update(requirement_params)
      redirect_to admin_document_requirement_path(@requirement), notice: "Requisito actualizado."
    else
      render :edit
    end
  end

  def destroy
    @requirement.destroy
    redirect_to admin_document_requirements_path, notice: "Requisito eliminado."
  end

  private

  def set_requirement
    @requirement = DocumentRequirement.find(params[:id])
  end

  def requirement_params
    params.require(:document_requirement).permit(
      :document_type_id, :property_type,
      :transaction_type, :client_type,
      :person_type, :valid_from,
      :valid_until, :is_required,
      :applies_to
    )
  end
end
