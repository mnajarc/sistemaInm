class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # usuario invitado (guest)
    
    # ✅ ACTUALIZADO: Soporte para superadmin
    case user.role&.to_s
    when 'superadmin'
      # SuperAdmin puede hacer TODO
      can :manage, :all
      can :access, :superadmin_panel
      can :manage, :menu_configuration
      can :manage, :role_configuration
      
    when 'admin'
      # Admin puede gestionar usuarios y propiedades, pero NO configuración de sistema
      can :manage, :all
      cannot :access, :superadmin_panel
      cannot :manage, :menu_configuration
      cannot :manage, :role_configuration
      
    when 'agent'
      can :read, :all
      can :create, Property
      can [:update, :destroy], Property, user: user
      can :read, User # Puede ver otros usuarios pero no modificar
      
    when 'client'
      can :read, Property
      
    else
      # Usuario guest o sin rol
      can :read, Property
    end
  end
end
