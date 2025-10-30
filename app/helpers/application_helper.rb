module ApplicationHelper
  def system_name
    InstanceConfig.current.app_name.presence || "Sistema Inmobiliario"
  end

  def app_name
    InstanceConfig.current.app_name
  end

  def app_logo
    InstanceConfig.current.app_logo
  end

  def organization_name
    InstanceConfig.current.organization_name
  end
  
  def instance_private?
    !InstanceConfig.current.allow_external_access
  end
  # ============================================================================
  # HELPERS PARA ÁREAS ADMINISTRATIVAS
  # ============================================================================
  
  def admin_area?
    controller_path.start_with?("admin/")
  end

  def superadmin_area?
    controller_path.start_with?("superadmin/")
  end

  def can_access_admin?
    current_user&.admin_or_above?
  end

  def can_access_superadmin?
    current_user&.superadmin?
  end

  # ============================================================================
  # HELPERS PARA ROLES Y BADGES
  # ============================================================================

  def role_badge_class(role_name_or_level)
    if role_name_or_level.is_a?(String)
      case role_name_or_level
      when "superadmin" then "warning"
      when "admin" then "danger"
      when "agent" then "primary"
      when "client" then "secondary"
      else "info"
      end
    elsif role_name_or_level.is_a?(Integer)
      case role_name_or_level
      when 0 then "warning"
      when 1..9 then "warning"
      when 10 then "danger"
      when 11..19 then "info"
      when 20 then "primary"
      when 21..29 then "success"
      when 30..99 then "secondary"
      else "dark"
      end
    else
      "secondary"
    end
  end

  def role_name(role_name)
    case role_name.to_s
    when "superadmin" then "Superadministrador"
    when "admin" then "Administrador"
    when "agent" then "Agente"
    when "client" then "Cliente"
    else "Sin rol"
    end
  end

  def role_badge(user)
    role_name = user.role&.display_name || t('roles.client', default: 'Cliente')
    badge_class = case user.role&.name
                  when 'superadmin' then 'bg-danger'
                  when 'admin' then 'bg-warning text-dark'
                  when 'agent' then 'bg-primary'
                  when 'client' then 'bg-secondary'
                  else 'bg-light text-dark'
                  end
    
    content_tag :span, role_name, class: "badge #{badge_class}"
  end

  # ============================================================================
  # HELPERS PARA FLASH MESSAGES
  # ============================================================================

  def bootstrap_alert_class(flash_type)
    case flash_type.to_s
    when "notice", "success" then "success"
    when "alert", "error" then "danger"
    when "warning" then "warning"
    else "info"
    end
  end

  # ============================================================================
  # HELPERS PARA MENÚS DINÁMICOS (VERSIÓN BÁSICA)
  # ============================================================================

  def render_navbar_menu
    return unless user_signed_in?
    
    begin
      menu_items = MenuItem.main_navigation(current_user)
      
      content_tag :ul, class: "navbar-nav me-auto mb-2 mb-lg-0" do
        menu_items.map do |item|
          children = item.accessible_children_for_user(current_user)
          
          if children.any?
            # Menú con dropdown
            content_tag :li, class: "nav-item dropdown" do
              concat link_to "#", class: "nav-link dropdown-toggle", 
                            data: { bs_toggle: "dropdown" } do
                concat content_tag(:i, "", class: "bi #{item.icon}") if item.icon.present?
                concat " #{item.display_name}"
              end
              
              concat content_tag(:ul, class: "dropdown-menu") do
                children.map do |child|
                  content_tag :li do
                    link_to (child.path.present? ? child.path : "#"), class: "dropdown-item" do
                      concat content_tag(:i, "", class: "bi #{child.icon}") if child.icon.present?
                      concat " #{child.display_name}"
                    end
                  end
                end.join.html_safe
              end
            end
          else
            # Menú simple
            content_tag :li, class: "nav-item" do
              link_to (item.path.present? ? item.path : "#"), class: "nav-link" do
                concat content_tag(:i, "", class: "bi #{item.icon}") if item.icon.present?
                concat " #{item.display_name}"
              end
            end
          end
        end.join.html_safe
      end
    rescue => e
      Rails.logger.error "Menu error: #{e.message}"
      content_tag :ul, class: "navbar-nav me-auto mb-2 mb-lg-0" do
        content_tag :li, class: "nav-item" do
          content_tag :span, "Error menús", class: "nav-link text-warning"
        end
      end
    end
  end


  def render_dynamic_menu_item(item)
    if item.has_children?
      render_dropdown_menu(item)
    else
      render_single_menu(item)
    end
  end

  def render_single_menu(item)
    content_tag :li, class: "nav-item" do
      link_to (item.path.present? ? item.path : "#"), class: "nav-link" do
        concat content_tag(:i, "", class: "bi #{item.icon}") if item.icon.present?
        concat " #{item.display_name}"
      end
    end
  end

  def render_dropdown_menu(item)
    content_tag :li, class: "nav-item dropdown" do
      concat link_to "#", class: "nav-link dropdown-toggle", 
                    data: { bs_toggle: "dropdown" } do
        concat content_tag(:i, "", class: "bi #{item.icon}") if item.icon.present?
        concat " #{item.display_name}"
      end
      
      concat content_tag(:ul, class: "dropdown-menu") do
        item.accessible_children_for_user(current_user).map do |child|
          content_tag :li do
            link_to (child.path.present? ? child.path : "#"), class: "dropdown-item" do
              concat content_tag(:i, "", class: "bi #{child.icon}") if child.icon.present?
              concat " #{child.display_name}"
            end
          end
        end.join.html_safe
      end
    end
  end  

  # ============================================================================
  # HELPERS PARA UI Y FORMATEO
  # ============================================================================

  def page_title(title = nil)
    base_title = "Sistema Inmobiliario"
    if title.present?
      "#{title} | #{base_title}"
    else
      base_title
    end
  end

  def format_currency(amount)
    return "N/A" if amount.blank?
    number_to_currency(amount, unit: "$", precision: 2, delimiter: ",")
  end

  def format_area(area_m2)
    return "N/A" if area_m2.blank?
    "#{number_with_delimiter(area_m2)} m²"
  end

  def property_type_icon(property_type)
    case property_type.to_s.downcase
    when 'house', 'casa' then 'bi-house'
    when 'apartment', 'departamento' then 'bi-building'
    when 'commercial', 'local_comercial' then 'bi-shop'
    when 'office', 'oficina' then 'bi-briefcase'
    when 'warehouse', 'bodega' then 'bi-box'
    when 'land', 'terreno' then 'bi-map'
    else 'bi-house-door'
    end
  end

  def operation_type_icon(operation_type)
    case operation_type.to_s.downcase
    when 'sale', 'venta' then 'bi-currency-dollar'
    when 'rent', 'alquiler' then 'bi-calendar-check'
    when 'short_rent', 'alquiler_temporario' then 'bi-calendar-week'
    else 'bi-briefcase'
    end
  end

  def status_badge(status, model_name = nil)
    case status.to_s.downcase
    when 'active', 'available', 'activo', 'disponible'
      content_tag :span, status.humanize, class: "badge bg-success"
    when 'reserved', 'reservado'
      content_tag :span, status.humanize, class: "badge bg-warning text-dark"
    when 'sold', 'vendido'
      content_tag :span, status.humanize, class: "badge bg-info"
    when 'rented', 'alquilado'
      content_tag :span, status.humanize, class: "badge bg-primary"
    when 'inactive', 'cancelled', 'inactivo', 'cancelado'
      content_tag :span, status.humanize, class: "badge bg-danger"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end

  # ============================================================================
  # HELPERS AUXILIARES
  # ============================================================================

  def breadcrumb_trail(path)
    # Método básico por ahora
    ""
  end

end