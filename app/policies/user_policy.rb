class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.superadmin?
        relation.all                    # ✅ CORRECTO: relation
      elsif user.admin_or_above?
        relation.joins(:role).where(    # ✅ CORRECTO: relation  
          'roles.level > ?', user.role&.level || 999
        )
      else
        relation.where(id: user.id)     # ✅ CORRECTO: relation
      end
    end
  end
end
