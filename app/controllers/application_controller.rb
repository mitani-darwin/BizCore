class ApplicationController < ActionController::Base
  include AuthorizationHelper
  helper Admin::SidebarHelper

  helper_method :current_user, :current_tenant, :current_ability

  before_action :set_current_context

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def set_current_context
    Current.reset
    # TODO: Replace with real authentication and tenant switching when login is implemented.
    Current.user = find_current_user
    Current.tenant = Current.user&.tenant
  end

  def find_current_user
    return Current.user if Current.user.present?

    # Prefer Devise/Warden user when available, otherwise fall back to first user for mock login.
    begin
      super_user = defined?(super) ? super : nil
    rescue NoMethodError
      super_user = nil
    end

    super_user || User.first
  end

  def current_user
    Current.user
  end

  def current_tenant
    Current.tenant
  end

  def current_ability
    @current_ability ||= Ability.new(Current.user)
  end

  def render_not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
