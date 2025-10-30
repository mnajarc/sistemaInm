class Superadmin::MenuItemsController < Superadmin::BaseController
  before_action :ensure_superadmin
  before_action :set_menu_item, only: [ :show, :edit, :update, :destroy ]
  def index
    @menu_items = policy_scope(MenuItem)
                   .where(active: true)
                   .where('minimum_role_level >= ?', current_user.role_level)
                   .order(:sort_order)
    @root_items = MenuItem.roots.by_sort_order
    # authorize MenuItem  # ✅ COMENTAR TEMPORALMENTE
  end

  def show
    authorize @menu_item
  end

  def new
    @menu_item = MenuItem.new
    @parent_options = parent_menu_options
    @role_levels = available_role_levels
    authorize MenuItem
  end

  def create
    @menu_item = MenuItem.new(menu_item_params)
    authorize @menu_item
    if @menu_item.save
      create_default_permissions(@menu_item)
      redirect_to superadmin_menu_items_path,
                 notice: "Menú '#{@menu_item.display_name}' creado exitosamente"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @menu_item
    @parent_options = parent_menu_options(@menu_item)
    @role_levels = available_role_levels
  end

  def update
    authorize @menu_item
    if @menu_item.update(menu_item_params)
      update_permissions(@menu_item) if params[:menu_item][:minimum_role_level_changed]
      redirect_to superadmin_menu_items_path,
                 notice: "Menú '#{@menu_item.display_name}' actualizado exitosamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @menu_item
    if @menu_item.system_menu?
      redirect_to superadmin_menu_items_path,
                 alert: "No se pueden eliminar menús del sistema"
      return
    end

    if @menu_item.children.any?
      redirect_to superadmin_menu_items_path,
                 alert: "No se puede eliminar un menú que tiene submenús"
      return
    end

    name = @menu_item.display_name
    @menu_item.destroy
    redirect_to superadmin_menu_items_path,
               notice: "Menú '#{name}' eliminado exitosamente"
  end

  # Acción AJAX para reordenar menús
  def reorder
    authorize @menu_item
    params[:menu_items].each_with_index do |id, index|
      MenuItem.find(id).update(sort_order: (index + 1) * 10)
    end

    render json: { success: true, message: "Orden actualizado" }
  end

  private

  def set_menu_item
    @menu_item = MenuItem.find(params[:id])
  end

  def menu_item_params
    params.require(:menu_item).permit(
      :name, :display_name, :path, :icon, :parent_id,
      :sort_order, :minimum_role_level, :active
    )
  end

  def parent_menu_options(current_item = nil)
    items = MenuItem.where.not(id: current_item&.id)

    # No permitir que un menú sea hijo de sí mismo o de sus propios hijos
    if current_item
      descendant_ids = current_item.children.pluck(:id)
      descendant_ids << current_item.id
      items = items.where.not(id: descendant_ids)
    end

    [ [ "Sin padre (menú raíz)", nil ] ] +
    items.roots.map { |item| [ item.display_name, item.id ] } +
    items.where.not(parent_id: nil).map { |item| [ "└─ #{item.display_name}", item.id ] }
  end

  def available_role_levels
    [
      [ "SuperAdmin (0)", 0 ],
      [ "Admin (10)", 10 ],
      [ "Agente (20)", 20 ],
      [ "Cliente (30)", 30 ]
    ]
  end

  def create_default_permissions(menu_item)
    Role.active.each do |role|
      if role.level <= menu_item.minimum_role_level
        RoleMenuPermission.create!(
          role: role,
          menu_item: menu_item,
          can_view: true,
          can_edit: role.admin_or_above?
        )
      end
    end
  end

  def update_permissions(menu_item)
    # Eliminar permisos existentes
    menu_item.role_menu_permissions.destroy_all

    # Crear nuevos permisos basados en el nuevo nivel
    create_default_permissions(menu_item)
  end
end
