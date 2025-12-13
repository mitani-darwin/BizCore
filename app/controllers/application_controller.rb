class ApplicationController < ActionController::Base
  include Pundit::Authorization

  helper_method :current_tenant

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def current_tenant
    return @current_tenant if defined?(@current_tenant)

    @current_tenant = current_user&.tenant
  end

  def render_forbidden
    respond_to do |format|
      format.html { render file: Rails.root.join("public/403.html"), status: :forbidden, layout: false }
      format.any { head :forbidden }
    end
  end
end
