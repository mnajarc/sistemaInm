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

  def role_badge_class(role_name_or_level)
  # Si recibe un nombre de rol
    if role_name_or_level.is_a?(String)
      case role_name_or_level
      when 'superadmin'
        'warning'
      when 'admin' 
        'danger'
      when 'agent'
        'primary'
      when 'client'
        'secondary'
      else
        'info'  # Color por defecto para roles personalizados
      end
  # Si recibe un nivel numérico
    elsif role_name_or_level.is_a?(Integer)
      case role_name_or_level
      when 0
        'warning'   # SuperAdmin - Amarillo
      when 1..9
        'warning'   # Niveles altos
      when 10
        'danger'    # Admin - Rojo
      when 11..19
        'info'      # Niveles intermedios altos - Celeste
      when 20
        'primary'   # Agent - Azul
      when 21..29
        'success'   # Niveles intermedios bajos - Verde
      when 30..99
        'secondary' # Client y otros - Gris
      else
        'dark'      # Niveles muy altos
      end
    else
      'secondary' # Fallback
    end
  end

  def role_name(role_name)
    case role_name.to_s
    when 'superadmin'
      'Superadministrador'
    when 'admin'
      'Administrador'
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

