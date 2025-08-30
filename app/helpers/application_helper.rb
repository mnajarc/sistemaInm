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

end

