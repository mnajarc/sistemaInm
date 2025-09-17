module MenuHelper
  def render_menu_tree(menus, current_user)
    return '' if menus.empty?
    
    content_tag :ul, class: 'navbar-nav me-auto' do
      menus.each do |menu|
        concat render_menu_item(menu, current_user)
      end
    end
  end
  
  def render_admin_sidebar(current_user)
    begin
      admin_menus = MenuItem.admin_sidebar(current_user)
      
      content_tag :ul, class: 'nav nav-pills flex-column' do
        admin_menus.each do |menu|
          concat render_sidebar_item(menu, current_user)
        end
      end
    rescue
      # Fallback si hay errores
      content_tag :ul, class: 'nav nav-pills flex-column' do
        content_tag :li, class: 'nav-item' do
          link_to admin_property_types_path, class: 'nav-link' do
            content_tag(:i, '', class: 'bi-house me-2') + 'Tipos de Propiedad'
          end
        end
      end
    end
  end
  
  def breadcrumb_trail(current_path)
    parts = current_path.split('/').reject(&:blank?)
    
    content_tag :nav, 'aria-label': 'breadcrumb' do
      content_tag :ol, class: 'breadcrumb' do
        concat content_tag(:li, link_to('Inicio', root_path), class: 'breadcrumb-item')
        
        parts.each_with_index do |part, index|
          path = '/' + parts[0..index].join('/')
          is_last = index == parts.length - 1
          
          if is_last
            concat content_tag(:li, part.humanize, class: 'breadcrumb-item active')
          else
            concat content_tag(:li, link_to(part.humanize, path), class: 'breadcrumb-item')
          end
        end
      end
    end
  end
  
  private
  
  def render_menu_item(menu, current_user)
    return '' unless menu.accessible_to?(current_user)
    
    if menu.has_children?
      render_dropdown_menu(menu, current_user)
    else
      render_simple_menu(menu)
    end
  end
  
  def render_dropdown_menu(menu, current_user)
    accessible_children = menu.children.select { |child| child.accessible_to?(current_user) }
    return '' if accessible_children.empty?
    
    content_tag :li, class: 'nav-item dropdown' do
      link_content = content_tag(:a, class: 'nav-link dropdown-toggle', 
                                 href: '#', role: 'button', 
                                 'data-bs-toggle': 'dropdown') do
        concat content_tag(:i, '', class: menu.icon) if menu.icon.present?
        concat ' ' + menu.display_name
      end
      
      dropdown_content = content_tag(:ul, class: 'dropdown-menu') do
        accessible_children.each do |child|
          concat content_tag(:li, link_to(child.display_name, child.path, class: 'dropdown-item'))
        end
      end
      
      link_content + dropdown_content
    end
  end
  
  def render_simple_menu(menu)
    content_tag :li, class: 'nav-item' do
      link_to menu.path, class: "nav-link #{'active' if current_page?(menu.path)}" do
        concat content_tag(:i, '', class: menu.icon) if menu.icon.present?
        concat ' ' + menu.display_name
      end
    end
  end
  
  def render_sidebar_item(menu, current_user)
    return '' unless menu.accessible_to?(current_user)
    
    content_tag :li, class: 'nav-item' do
      link_to menu.path, class: "nav-link #{'active' if current_page?(menu.path)}" do
        concat content_tag(:i, '', class: "#{menu.icon} me-2") if menu.icon.present?
        concat menu.display_name
      end
    end
  end
end
