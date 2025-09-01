class Admin::UsersController < ApplicationController
  before_action :ensure_admin_or_superadmin
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :ensure_can_manage_user, only: [:edit, :update, :destroy]
  
  def index
    # ✅ FILTRAR: Solo mostrar usuarios que el actual puede gestionar
    @users = User.manageable_by(current_user).order(:email)
    @users = @users.where("email ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?
    
    # ✅ Incluir información de jerarquía para la vista
    @manageable_roles = available_roles_for_assignment
  end
  
  def show
  end
  
  def edit
  end
=begin
comentado para incluir versión corregida de update
  def update
    # ✅ PROTECCIÓN: Verificar autorización específica para el cambio
    if params[:user][:role].present?
      new_role = params[:user][:role]
      unless @user.can_change_role_to?(new_role, current_user)
        redirect_to admin_users_path, 
                   alert: "No tienes permisos para asignar el rol '#{new_role}' a #{@user.email}"
        return
      end
    end
    
    # ✅ Prevenir que el admin actual se quite sus propios permisos
    if @user == current_user && params[:user][:role] != current_user.role
      redirect_to admin_users_path, 
                 alert: "No puedes cambiar tu propio rol"
      return
    end
    
    # ✅ Asignar quien hace el cambio para validaciones
    @user.role_changer = current_user
    
    if @user.update(user_params)
      # Log del cambio de rol
      Rails.logger.info "✅ CAMBIO DE ROL AUTORIZADO:"
      Rails.logger.info "   #{current_user.email} (#{current_user.role}) cambió rol de #{@user.email} a #{@user.role}"
      redirect_to admin_users_path, notice: "Usuario actualizado exitosamente"
    else
      render :edit
    end
  end
=end

  def update
    # ✅ DEBUG (remover después)
    if params[:user][:role].present?
      @user.debug_role_change(params[:user][:role], current_user) if Rails.env.development?
    end
    
    # Verificar autorización específica para el cambio
    if params[:user][:role].present?
      new_role = params[:user][:role]
      unless @user.can_change_role_to?(new_role, current_user)
        redirect_to admin_users_path, 
                  alert: "No tienes permisos para asignar el rol '#{new_role}' a #{@user.email}"
        return
      end
    end
    
    # Prevenir que el admin actual se quite sus propios permisos
    if @user == current_user && params[:user][:role] != current_user.role
      redirect_to admin_users_path, 
                alert: "No puedes cambiar tu propio rol"
      return
    end
    
    # Asignar quien hace el cambio para validaciones
    @user.role_changer = current_user
    
    if @user.update(user_params)
      Rails.logger.info "✅ CAMBIO DE ROL AUTORIZADO:"
      Rails.logger.info "   #{current_user.email} (#{current_user.role}) cambió rol de #{@user.email} a #{@user.role}"
      redirect_to admin_users_path, notice: "Usuario actualizado exitosamente"
    else
      render :edit
    end
  end


  def destroy
    # ✅ PROTECCIÓN: No puede eliminar usuarios de nivel superior o igual
    unless @user.can_be_managed_by?(current_user)
      redirect_to admin_users_path, 
                 alert: "No tienes permisos para eliminar a este usuario"
      return
    end
    
    if @user == current_user
      redirect_to admin_users_path, alert: "No puedes eliminar tu propia cuenta"
      return
    end
    
    @user.destroy
    Rails.logger.info "🗑️ USUARIO ELIMINADO: #{current_user.email} eliminó a #{@user.email}"
    redirect_to admin_users_path, notice: "Usuario eliminado exitosamente"
  end
  
  def change_role
    @user = User.manageable_by(current_user).find(params[:id])
    
    # ✅ PROTECCIÓN: Verificar autorización para el nuevo rol
    new_role = params[:role]
    unless @user.can_change_role_to?(new_role, current_user)
      render json: { 
        success: false, 
        message: "No tienes permisos para asignar el rol '#{new_role}' a este usuario" 
      }
      return
    end
    
    if @user == current_user && new_role != current_user.role
      render json: { success: false, message: "No puedes cambiar tu propio rol" }
      return
    end
    
    old_role = @user.role
    @user.role_changer = current_user
    
    if @user.update(role: new_role)
      Rails.logger.info "✅ CAMBIO DE ROL VIA AJAX: #{current_user.email} cambió #{@user.email} de #{old_role} a #{@user.role}"
      
      render json: { 
        success: true, 
        message: "Rol actualizado a #{@user.role_name}",
        new_role: @user.role 
      }
    else
      render json: { 
        success: false, 
        message: @user.errors.full_messages.join(', ') 
      }
    end
    
  rescue ActiveRecord::RecordNotFound
    render json: { 
      success: false, 
      message: "No tienes permisos para modificar este usuario" 
    }
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:role, :active)
  end
  
  def ensure_admin_or_superadmin
    unless current_user&.admin_or_above?
      redirect_to root_path, alert: "Acceso denegado"
    end
  end
  
  def ensure_can_manage_user
    unless @user.can_be_managed_by?(current_user)
      redirect_to admin_users_path, 
                 alert: "No tienes permisos para gestionar este usuario"
    end
  end
  
  def available_roles_for_assignment
    # ✅ Solo mostrar roles que el usuario actual puede asignar
    case current_user.role
    when 'superadmin'
      User.roles.keys
    when 'admin'
      User.roles.select { |k, v| v > current_user.role_before_type_cast }.keys
    else
      []
    end
  end
end
