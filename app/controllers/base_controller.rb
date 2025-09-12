# app/controllers/base_controller.rb
class BaseController < ApplicationController
    include Pundit::Authorization
    
    before_action :authenticate_user!
    after_action :verify_authorized, except: [:index, :show]
    after_action :verify_policy_scoped, only: :index
    
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    protected
    
    def pundit_user
      current_user
    end
    
    private
    
    def user_not_authorized
      flash[:alert] = "No tienes permisos para realizar esta acción"
      redirect_to(request.referrer || root_path)
    end
  end
  