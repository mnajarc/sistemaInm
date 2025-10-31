class BusinessTransactionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
=begin
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

  def export_documents?
    # Permite exportar a admins, superadmins y agentes asignados
    user.admin? || 
    user.superadmin? || 
    record.listing_agent == user || 
    record.current_agent == user || 
    record.selling_agent == user
  end
=end

    def resolve
      if user.admin? || user.superadmin?
        relation.all
      elsif user.agent?
        relation.where(current_agent_id: user.id)
          .or(relation.where(listing_agent_id: user.id))
          .or(relation.where(selling_agent_id: user.id))
      elsif user.client?
        relation.where(offering_client_id: user.client&.id)
          .or(relation.where(acquiring_client_id: user.client&.id))
      else
        relation.none
      end
    end
  end

  def index?
    true
  end

  def show?
    user.admin? || user.superadmin? || 
    record.listing_agent == user || 
    record.current_agent == user || 
    record.selling_agent == user ||
    (user.client? && (record.offering_client&.user == user || record.acquiring_client&.user == user))
  end

  def create?
    user.agent? || user.admin? || user.superadmin?
  end

  def new?
    create?
  end

  def update?
    user.admin? || user.superadmin? || 
    record.current_agent == user || 
    record.listing_agent == user
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || user.superadmin?
  end

  def transfer_agent?
    user.admin? || user.superadmin?
  end

  # NUEVO: Método para exportar documentos
  def export_documents?
    # Permite exportar a:
    # - Admins y superadmins
    # - Agentes asignados a la transacción
    user.admin? || 
    user.superadmin? || 
    record.listing_agent == user || 
    record.current_agent == user || 
    record.selling_agent == user
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
