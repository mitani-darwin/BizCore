module Admin
  class BaseController < ::ApplicationController
    layout "admin"

    before_action :ensure_current_tenant!
    before_action :require_permission!
    after_action :write_audit_log

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

    def write_audit_log
      return unless audit_loggable_action?

      AuditLogger.log(
        tenant: Current.tenant,
        user: Current.user,
        action: action_name,
        auditable: audit_target_record,
        request: request
      )
    rescue => e
      Rails.logger.error("[AuditLog] failed to write audit log: #{e.class} #{e.message}")
    end

    def audit_loggable_action?
      %w[create update destroy].include?(action_name) &&
        Current.tenant.present? &&
        response&.status.to_i < 400
    end

    def audit_target_record
      instance_variable_get("@#{controller_name.singularize}")
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
