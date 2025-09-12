class BusinessStatusPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
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
      user.superadmin?
    end
  end
  