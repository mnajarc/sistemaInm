# app/controllers/admin/document_validity_rules_controller.rb
class Admin::DocumentValidityRulesController < Admin::BaseController
  before_action :set_rule, only: [:show, :edit, :update, :destroy]

  def index
    @rules = DocumentValidityRule.includes(:document_type).order(:valid_from)
  end

  def show
  end

  def new
    @rule = DocumentValidityRule.new(valid_from: Date.current, is_active: true)
  end

  def create
    @rule = DocumentValidityRule.new(rule_params)
    if @rule.save
      redirect_to admin_document_validity_rule_path(@rule), notice: 'Regla de vigencia creada.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @rule.update(rule_params)
      redirect_to admin_document_validity_rule_path(@rule), notice: 'Regla de vigencia actualizada.'
    else
      render :edit
    end
  end

  def destroy
    @rule.destroy
    redirect_to admin_document_validity_rules_path, notice: 'Regla de vigencia eliminada.'
  end

  private

  def set_rule
    @rule = DocumentValidityRule.find(params[:id])
  end

  def rule_params
    params.require(:document_validity_rule).permit(
      :document_type_id, :validity_period_months,
      :valid_from, :valid_until, :is_active
    )
  end
end
