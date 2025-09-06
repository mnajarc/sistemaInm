# app/policies/property_policy.rb
class PropertyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user.role&.name
      when 'superadmin', 'admin'
        scope.all
      when 'agent'
        scope.where(user: user)
      when 'client'
        scope.joins(:property_status).where(property_statuses: { is_available: true })
      else
        scope.none
      end
    end
  end
  
  def index?
    true # Todos pueden ver listado (filtrado por scope)
  end
  
  def show?
    case user.role&.name
    when 'superadmin', 'admin'
      true
    when 'agent'
      record.user == user || record.property_status&.is_available
    when 'client'
      record.property_status&.is_available
    else
      false
    end
  end
  
  def create?
    user.role&.level && user.role.level <= 20 # Agent o superior
  end
  
  def update?
    case user.role&.name
    when 'superadmin', 'admin'
      true
    when 'agent'
      record.user == user
    else
      false
    end
  end
  
  def destroy?
    case user.role&.name
    when 'superadmin', 'admin'
      true
    when 'agent'
      record.user == user && record.property_status&.name != 'sold'
    else
      false
    end
  end
end
