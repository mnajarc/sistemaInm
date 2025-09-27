class BusinessTransactionCoOwnerPolicy < ApplicationPolicy
  def index?
    user.agent_or_above?
  end

  def show?
    return true if user.admin_or_above?
    return false unless user.agent?
    
    # Agente puede ver copropietarios de sus transacciones
    record.business_transaction.current_agent == user ||
    record.business_transaction.listing_agent == user
  end

  def create?
    return true if user.admin_or_above?
    return false unless user.agent?
    
    # Agente puede crear copropietarios en sus transacciones
    record.business_transaction.current_agent == user ||
    record.business_transaction.listing_agent == user
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user.admin_or_above?
        relation.all
      elsif user.agent?
        # Solo copropietarios de transacciones del agente
        relation.joins(:business_transaction)
                .where(business_transactions: { current_agent: user })
                .or(relation.joins(:business_transaction)
                           .where(business_transactions: { listing_agent: user }))
      else
        relation.none
      end
    end
  end
end
