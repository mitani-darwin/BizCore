module Admin
  class BaseController < ::ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :ensure_current_tenant!
    before_action :authorize_admin_entry

    helper_method :current_admin_user

    private

    def authorize_admin_entry
      authorize [:admin, :dashboard], :access?
    end

    def ensure_current_tenant!
      return if current_tenant.present?

      render_forbidden
      false
    end

    def current_admin_user
      current_user
    end
  end
end
