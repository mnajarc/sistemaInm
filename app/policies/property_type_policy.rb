class PropertyTypePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Pundit 2.5+ uses 'relation' instead of 'scope'
    def resolve
      if user.admin_or_above?
        relation.all
      else
        relation.none
      end
    end
  end

  def index?
    user.admin_or_above?
  end

  def show?
    user.admin_or_above?
  end

  def create?
    user.admin_or_above?
  end

  def new?
    create?
  end

  def update?
    user.admin_or_above?
  end

  def edit?
    update?
  end

  def destroy?
    user.superadmin? # Only superadmin can delete catalog items
  end
end
