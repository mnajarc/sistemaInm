module SuperadminHelper
  def render_menu_admin_tree(items, level = 0)
    return '' if items.empty?
    
    content_tag :ul, class: "list-unstyled #{'ms-3' if level > 0}" do
      items.map do |item|
        render_menu_admin_item(item, level)
      end.join.html_safe
    end
  end
  
  private
  
  def render_menu_admin_item(item, level)
    children = item.children.active.by_sort_order
    
    content_tag :li, class: "mb-2", data: { menu_id: item.id } do
      # Item principal
      item_content = content_tag :div, class: "d-flex align-items-center p-2 border rounded #{'bg-light' if item.system_menu?}" do
        icon_part = if item.icon.present?
          content_tag(:i, '', class: "#{item.icon} me-2")
        else
          content_tag(:i, '', class: "bi bi-circle me-2")
        end
        
        name_part = content_tag :span, class: "flex-grow-1" do
          content_tag(:strong, item.display_name) +
          if item.path.present?
            content_tag(:br) + content_tag(:small, item.path, class: "text-muted")
          else
            content_tag(:small, " (contenedor)", class: "text-muted")
          end
        end
        
        badges_part = content_tag :div do
          level_badge = content_tag(:span, "Nivel #{item.minimum_role_level}", 
                                   class: "badge bg-secondary me-1")
          status_badge = content_tag(:span, item.active? ? 'Activo' : 'Inactivo',
                                    class: "badge bg-#{item.active? ? 'success' : 'danger'} me-1")
          system_badge = if item.system_menu?
            content_tag(:span, 'Sistema', class: "badge bg-warning")
          else
            ''
          end
          
          level_badge + status_badge + system_badge
        end
        
        actions_part = content_tag :div, class: "ms-2" do
          edit_link = link_to edit_superadmin_menu_item_path(item), 
                             class: "btn btn-sm btn-outline-primary me-1" do
            content_tag(:i, '', class: "bi bi-pencil")
          end
          
          unless item.system_menu?
            delete_link = link_to superadmin_menu_item_path(item), 
                                 method: :delete,
                                 data: { confirm: "¿Eliminar '#{item.display_name}'?" },
                                 class: "btn btn-sm btn-outline-danger" do
              content_tag(:i, '', class: "bi bi-trash")
            end
            edit_link + delete_link
          else
            edit_link
          end
        end
        
        icon_part + name_part + badges_part + actions_part
      end
      
      # Hijos recursivos
      children_content = if children.any?
        render_menu_admin_tree(children, level + 1)
      else
        ''
      end
      
      item_content + children_content
    end
  end
end
