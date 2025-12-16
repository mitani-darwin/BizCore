module Admin
  class BaseController < ::ApplicationController
    layout "admin"

    before_action :ensure_current_tenant!
    before_action :require_permission!

    helper_method :current_admin_user, :required_permission_key

    private

    def ensure_current_tenant!
      return if current_tenant

      render_not_found and return false
    end

    def current_admin_user
      current_user
    end

    def require_permission!
      return if current_ability.can?(required_permission_key)

      render_not_found and return false
    end

    def required_permission_key
      action =
        case action_name
        when "new", "create"
          "create"
        when "edit", "update"
          "update"
        else
          action_name
        end

      "admin.#{controller_name}.#{action}"
    end
  end
end
