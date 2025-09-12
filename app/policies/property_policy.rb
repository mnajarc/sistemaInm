# app/policies/property_policy.rb
class PropertyPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role&.name
      when 'superadmin', 'admin'
        relation.all
      when 'agent'
        relation.where(user: user)
      when 'client'
        # Los clients no pueden ver propiedades directamente
        # Verán solo las que están en negocios disponibles
        relation.none
      else
        relation.none
      end
    end
  end
  
  def index?
    user.role&.level && user.role.level <= 20 # Solo Agent+
  end
  
  def show?
    case user.role&.name
    when 'superadmin', 'admin'
      true
    when 'agent'
      record.user == user
    when 'client'
      false # Los clients verán propiedades a través de BusinessTransactions
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
      record.user == user
    else
      false
    end
  end
end
