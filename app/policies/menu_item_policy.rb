class MenuItemPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin?
        relation.all
      else
        relation.none
      end
    end
  end

  def index?
    user.superadmin?
  end

  def show?
    user.superadmin?
  end

  def create?
    user.superadmin?
  end

  def new?
    create?
  end

  def update?
    user.superadmin?
  end

  def edit?
    update?
  end

  def destroy?
    user.superadmin? && !record.system_menu?
  end
end
