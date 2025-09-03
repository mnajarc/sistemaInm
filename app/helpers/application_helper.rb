module ApplicationHelper
  def admin_area?
    controller_path.start_with?('admin/')
  end
  
  def page_title(title = nil)
    if title
      content_for :title, "#{title} - Sistema Inmobiliario"
    else
      content_for?(:title) ? yield(:title) : "Sistema Inmobiliario"
    end
  end
    
  def bootstrap_alert_class(flash_type)
    case flash_type.to_s
    when 'notice', 'success'
      'success'
    when 'alert', 'error'
      'danger'
    when 'warning'
      'warning'
    else
      'info'
    end
  end

  def role_name(role)
    case role.to_s
    when 'admin'
      'Administrador'
    when 'agent'
      'Agente'
    when 'client'
      'Consulta'
    else
      'Sin rol'
    end
  end
  
  def role_badge_class(role)
    case role.to_s
    when 'admin'
      'danger'
    when 'agent'
      'primary'
    when 'client'
      'secondary'
    else
      'light'
    end
  end

    def can_access_admin?
      current_user&.admin_or_above?
    end

    def can_access_superadmin?
      current_user&.superadmin?
    end

    def admin_area?
      controller_path.start_with?('admin/')
    end

    def superadmin_area?
      controller_path.start_with?('superadmin/')
    end
  
    def role_badge_class(role)
      case role.to_s
      when 'admin'
        'danger'
      when 'superadmin'
        'warning'
      when 'agent'
        'primary'
      when 'client'
        'secondary'
      else
        'light'
      end
    end

  def role_name(role)
    case role.to_s
    when 'admin'
      'Administrador'
    when 'superadmin'
      'Superadministrador'
    when 'agent'
      'Agente'
    when 'client'
      'Cliente'
    else
      'Sin rol'
    end
  end

  def bootstrap_alert_class(flash_type)
    case flash_type.to_s
    when 'notice', 'success'
      'success'
    when 'alert', 'error'
      'danger'
    when 'warning'
      'warning'
    else
      'info'
    end
  end

end

