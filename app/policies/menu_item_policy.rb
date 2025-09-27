class MenuItemPolicy < ApplicationPolicy
  class Scope < Scope    # 🚩 AGREGAR ESTO:
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end
    
    def resolve
      user.superadmin? ?  scope.all : scope.none
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
    user.superadmin?
  end
end
