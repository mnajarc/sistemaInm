class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  allow_browser versions: :modern
  protected

  def after_sign_in_path_for(resource)
    # stored_location_for(resource) || root_path
    Rails.logger.debug "REDIRECT DEBUG: User #{resource.email} signed in, redirecting to rootr_ path"
    root_path
  end
end
