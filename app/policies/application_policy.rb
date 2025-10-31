class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def export_documents?
    # Permite exportar a: admin, agentes, y al agente asignado
    user.admin? || 
    user.agent? || 
    record.listing_agent == user || 
    record.current_agent == user || 
    record.selling_agent == user
  end

  class Scope
    attr_reader :user, :relation

    def initialize(user, relation)
      @user = user
      @relation = relation
    end

    def resolve
      relation.none
    end
  end
end
