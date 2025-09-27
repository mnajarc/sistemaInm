class RolePolicy < ApplicationPolicy
  def index?
    user.superadmin?
  end

  def show?
    user.superadmin?
  end

  def new?
    user.superadmin?
  end
  alias create? new?

  def edit?
    user.superadmin? && !record.system_role?
  end
  alias update? edit?

  def destroy?
    user.superadmin? && !record.system_role? && record.users.none?
  end

  class Scope < Scope
    def resolve
      if user.superadmin?
        scope.all
      else
        scope.none
      end
    end
  end
end
