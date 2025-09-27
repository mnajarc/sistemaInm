class CoOwnershipTypePolicy < ApplicationPolicy
  def index?;      user.admin_or_above?; end
  def show?;       user.admin_or_above?; end
  def new?;        user.admin_or_above?; end
  alias create? new?
  def edit?;       user.admin_or_above?; end
  alias update? edit?
  def destroy?;    user.admin_or_above?; end

  class Scope < Scope
    def resolve
      if user.admin_or_above?
        relation.order(:sort_order)
      else
        relation.none
      end
    end
  end
end
