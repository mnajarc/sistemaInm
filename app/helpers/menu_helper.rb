module MenuHelper
  def user_menu_items(user, parent = nil)
    base_query = MenuItem.active.by_sort_order
    base_query = parent ? base_query.where(parent: parent) : base_query.roots
    
    base_query.select { |item| user.can_access_menu?(item) }
  end
  
  def render_menu_tree(user, parent = nil, css_class = 'nav')
    menu_items = user_menu_items(user, parent)
    return '' if menu_items.empty?
    
    content_tag :ul, class: css_class do
      menu_items.map do |item|
        render_menu_item(user, item)
      end.join.html_safe
    end
  end
  
  private
  
  def render_menu_item(user, item)
    children = user_menu_items(user, item)
    has_children = children.any?
    
    css_classes = ['nav-item']
    css_classes << 'dropdown' if has_children
    
    content_tag :li, class: css_classes.join(' ') do
      link_content = if has_children
        dropdown_link(item)
      else
        simple_link(item)
      end
      
      children_content = if has_children
        content_tag(:ul, class: 'dropdown-menu') do
          children.map { |child| render_dropdown_item(child) }.join.html_safe
        end
      else
        ''
      end
      
      link_content + children_content
    end
  end
  
  def dropdown_link(item)
    link_to '#', 
            class: 'nav-link dropdown-toggle', 
            data: { bs_toggle: 'dropdown' },
            'aria-expanded': false do
      icon_tag(item.icon) + item.display_name
    end
  end
  
  def simple_link(item)
    link_to item.path, class: 'nav-link' do
      icon_tag(item.icon) + item.display_name
    end
  end
  
  def render_dropdown_item(item)
    content_tag :li do
      link_to item.path, class: 'dropdown-item' do
        icon_tag(item.icon) + item.display_name
      end
    end
  end
  
  def icon_tag(icon_class)
    return '' unless icon_class.present?
    content_tag(:i, '', class: icon_class) + ' '
  end
  # Agregar al final del archivo existente
  def render_admin_menu_items(user)
    return '' unless user&.admin_or_above?
    
    # Buscar menú de administración
    admin_menu = MenuItem.find_by(name: 'administration')
    return '' unless admin_menu
    
    # Obtener submenús que el usuario puede ver
    menu_items = user.role.menu_items
                    .where(parent_id: admin_menu.id, active: true)
                    .order(:sort_order)
    
    html = ''
    menu_items.each do |item|
      html += content_tag(:li) do
        link_to item.path, class: "dropdown-item" do
          icon_html = item.icon.present? ? content_tag(:i, '', class: "#{item.icon} me-2") : ''
          (icon_html + item.display_name).html_safe
        end
      end
    end
    
    html.html_safe
  end

end
