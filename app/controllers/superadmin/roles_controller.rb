class Superadmin::RolesController < Superadmin::BaseController
  before_action :set_role, only: [ :show, :edit, :update, :destroy ]

  def index
    @roles = Role.by_level.includes(:users)
    @system_roles = Role.system_roles
    @custom_roles = Role.where(system_role: false)
  end

  def show
    authorize @role
    @users_with_role = @role.users.includes(:properties)
    @menu_permissions = @role.role_menu_permissions.includes(:menu_item)
  end

  def new
    @role = Role.new
    @available_levels = available_role_levels
    authorize @role
  end

  def create
    @role = Role.new(role_params)
    authorize @role

    if @role.save
      create_menu_permissions(@role)
      redirect_to superadmin_roles_path,
                 notice: "Rol '#{@role.display_name}' creado exitosamente"
    else
      @available_levels = available_role_levels
      render :new
    end
  end

  def edit
    authorize @role
    if @role.system_role?
      redirect_to superadmin_roles_path,
                 alert: "No se pueden editar roles del sistema"
      return
    end

    @available_levels = available_role_levels(@role)
  end

  def update
    authorize @role
    if @role.system_role?
      redirect_to superadmin_roles_path,
                 alert: "No se pueden modificar roles del sistema"
      return
    end

    if @role.update(role_params)
      update_menu_permissions(@role) if params[:role][:level_changed]
      redirect_to superadmin_roles_path,
                 notice: "Rol '#{@role.display_name}' actualizado exitosamente"
    else
      @available_levels = available_role_levels(@role)
      render :edit
    end
  end

  def destroy
    authorize @role
    if @role.system_role?
      redirect_to superadmin_roles_path,
                 alert: "No se pueden eliminar roles del sistema"
      return
    end

    if @role.users.any?
      redirect_to superadmin_roles_path,
                 alert: "No se puede eliminar un rol que tiene usuarios asignados"
      return
    end

    name = @role.display_name
    @role.destroy
    redirect_to superadmin_roles_path,
               notice: "Rol '#{name}' eliminado exitosamente"
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :display_name, :description, :level, :active)
  end

  def available_role_levels(current_role = nil)
    used_levels = Role.where.not(id: current_role&.id).pluck(:level)

    (5..99).step(5).reject { |level| used_levels.include?(level) }.map do |level|
      [ "Nivel #{level}", level ]
    end
  end

  def create_menu_permissions(role)
    MenuItem.active.each do |menu_item|
      if role.level <= menu_item.minimum_role_level
        RoleMenuPermission.create!(
          role: role,
          menu_item: menu_item,
          can_view: true,
          can_edit: (role.level <= 10) # Solo admin y superiores pueden editar
        )
      end
    end
  end

  def update_menu_permissions(role)
    # Eliminar permisos existentes
    role.role_menu_permissions.destroy_all

    # Crear nuevos permisos
    create_menu_permissions(role)
  end
end
