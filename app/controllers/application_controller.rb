class ApplicationController < ActionController::Base
  include Pagy::Backend
  include AuthorizationHelper
  helper Admin::SidebarHelper
  helper Admin::WorkforceHelper
  helper Admin::ContractsHelper

  helper_method :current_user, :current_tenant, :current_employee, :current_ability

  before_action :set_current_context
  before_action :set_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def set_current_context
    Current.reset
    Current.user = warden.user(:user)
    Current.tenant = Current.user&.tenant
  end

  def set_locale
    preferred_locale = current_user&.locale.presence || I18n.default_locale
    locale = preferred_locale.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  rescue NoMethodError
    I18n.locale = I18n.default_locale
  end

  def current_user
    Current.user
  end

  def current_tenant
    Current.tenant
  end

  def current_employee
    current_user&.employee
  end

  def current_ability
    @current_ability ||= Ability.new(Current.user)
  end

  def render_not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end
