# app/policies/property_policy.rbclass PropertyPolicy < ApplicationPolicy
class PropertyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin? || user.admin?
        relation.all
      elsif user.agent?
        relation.where(user: user)
      elsif user.client?
        relation.none
      else
        relation.none
      end
    end
  end

  def index?
    user.agent_or_above?  # Usa tu método helper (level <= 20)
  end

  def show?
    return true if user.admin_or_above?
    return false unless user.agent?
    record.user == user  # Agente solo ve sus propiedades
  end

  def create?
    user.agent_or_above?  # Agentes pueden crear propiedades
  end

  def update?
    return true if user.admin_or_above?
    return false unless user.agent?
    record.user == user  # Agente solo edita sus propiedades
  end

  def destroy?
    return true if user.admin_or_above?
    return false unless user.agent?
    record.user == user  # Agente solo elimina sus propiedades
  end
end
