# app/policies/client_policy.rb
class ClientPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def search?
    user.present?
  end

  def create?
    user.agent_or_above? # Agentes, admins y superadmins pueden crear clientes
  end

end
