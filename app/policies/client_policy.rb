# app/policies/client_policy.rb
class ClientPolicy < ApplicationPolicy
    def create?
      user.agent_or_above? # Agentes, admins y superadmins pueden crear clientes
    end
  end
  