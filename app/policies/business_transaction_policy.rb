class BusinessTransactionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role&.name
      when "superadmin", "admin"
        relation.all
      when "agent"
        relation.where(current_agent: user)
      when "client"
        # Cliente solo ve transacciones donde es ofertante o adquiriente
        client_record = user.client || Client.find_by(email: user.email)
        if client_record
          relation.where(
            "offering_client_id = ? OR acquiring_client_id = ?",
            client_record.id, client_record.id
          )
        else
          relation.none
        end
      else
        relation.none
      end
    end
  end

  def index?
    user.agent_or_above? || user.client?
  end

  def show?
    case user.role&.name
    when "superadmin", "admin"
      true
    when "agent"
      record.current_agent == user || record.listing_agent == user
    when "client"
      client_record = user.client || Client.find_by(email: user.email)
      client_record && (
        record.offering_client == client_record ||
        record.acquiring_client == client_record
      )
    else
      false
    end
  end

  def create?
    user.agent_or_above?
  end

  def new?
    create?
  end

  def update?
    case user.role&.name
    when "superadmin", "admin"
      true
    when "agent"
      record.current_agent == user
    else
      false
    end
  end

  def edit?
    update?
  end

  def destroy?
    case user.role&.name
    when "superadmin"
      true
    when "agent"
      record.current_agent == user && record.business_status.name == "available"
    else
      false
    end
  end

  # Método adicional para gestión de copropietarios
  def manage_co_owners?
    case user.role&.name
    when "superadmin", "admin"
      true
    when "agent"
      record.current_agent == user || record.listing_agent == user
    else
      false
    end
  end
end
