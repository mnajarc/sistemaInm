class Agent::BaseController < BaseController
  before_action :ensure_agent

  private

  def ensure_agent
    unless current_user&.agent?
      redirect_to root_path, alert: "Acceso restringido a agentes"
    end
  end
end
