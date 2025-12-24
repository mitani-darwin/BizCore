module Admin
  class BaseController < ::ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :ensure_current_tenant!
    before_action :prepare_screen_context
    before_action :require_permission!
    around_action :with_audit_context
    after_action :write_automatic_audit_log

    helper_method :current_admin_user,
                  :required_permission_key,
                  :audit_context,
                  :navigation_sections,
                  :navigation_active?,
                  :navigation_path,
                  :screen,
                  :screen_action,
                  :page_title,
                  :breadcrumbs

    rescue_from AuthorizationError, with: :handle_authorization_error

    AUDITABLE_ACTIONS = %w[create update destroy].freeze
    SENSITIVE_AUDIT_KEYS = %w[
      encrypted_password
      password
      password_confirmation
      reset_password_token
      reset_password_sent_at
    ].freeze

    private

    def ensure_current_tenant!
      return if current_tenant

      render_not_found and return false
    end

    def current_admin_user
      current_user
    end

    def require_permission!
      authorize!(required_permission_key)
    end

    def required_permission_key
      return screen_action.permission_key if screen_action&.permission_key.present?

      action =
        case action_name
        when "index", "show"
          "read"
        when "new", "create"
          "create"
        when "edit", "update"
          "update"
        when "destroy"
          "delete"
        else
          action_name
        end

      "admin.#{controller_name}.#{action}"
    end

    def audit_context
      @audit_context ||= build_audit_context
    end

    def prepare_screen_context
      @screen = Admin::Screens.screen_for(controller_name)
      @screen_action = Admin::Screens.action_for(controller_name, action_name)
    end

    def screen
      @screen
    end

    def screen_action
      @screen_action
    end

    def page_title
      Admin::Screens.page_title_for(controller_name, action_name, record: audit_target_record)
    end

    def breadcrumbs
      Admin::Screens.breadcrumbs_for(self, controller_name, action_name, record: audit_target_record)
    end

    def build_audit_context
      {
        tenant_id: current_tenant&.id,
        actor: current_admin_user,
        request_id: request&.request_id,
        ip_address: request&.remote_ip,
        user_agent: request&.user_agent,
        path: request&.fullpath,
        http_method: request&.request_method
      }
    end

    def with_audit_context
      audit_context
      yield
    rescue AuthorizationError => e
      @audit_exception = e
      log_denied_audit(e)
      raise
    rescue => e
      @audit_exception = e
      log_failed_audit(e)
      raise
    end

    def audit!(action_key:, auditable: nil, metadata: {}, status: "succeeded")
      return unless audit_context[:tenant_id]

      AuditLog.create!(
        tenant_id: audit_context[:tenant_id],
        actor: audit_context[:actor],
        action_key: action_key,
        auditable: auditable,
        request_id: audit_context[:request_id],
        ip_address: audit_context[:ip_address],
        user_agent: audit_context[:user_agent],
        path: audit_context[:path],
        http_method: audit_context[:http_method],
        status: status,
        metadata: metadata.presence
      )
      @audit_recorded = true
    rescue => e
      Rails.logger.error("[AuditLog] failed to write audit log: #{e.class} #{e.message}")
    end

    def write_automatic_audit_log
      return if @audit_recorded
      return unless audit_loggable_action? && response_successful?

      audit!(
        action_key: required_permission_key,
        auditable: audit_target_record,
        metadata: default_audit_metadata
      )
    end

    def log_failed_audit(exception)
      return if @audit_recorded
      return unless audit_loggable_action?

      audit!(
        action_key: required_permission_key,
        auditable: audit_target_record,
        metadata: { error: "#{exception.class}: #{exception.message}" },
        status: "failed"
      )
    end

    def log_denied_audit(exception)
      return if @audit_recorded
      return unless audit_loggable_action?

      audit!(
        action_key: required_permission_key,
        auditable: audit_target_record,
        metadata: { error: exception.message },
        status: "denied"
      )
    end

    def audit_loggable_action?
      AUDITABLE_ACTIONS.include?(normalized_action_name) && audit_context[:tenant_id].present?
    end

    def normalized_action_name
      case action_name
      when "new" then "create"
      when "edit" then "update"
      else
        action_name
      end
    end

    def response_successful?
      status_code = response&.status.to_i
      status_code.positive? && status_code < 400
    end

    def handle_authorization_error(_error)
      # TODO: add dedicated forbidden screen and richer audit context.
      render_not_found
    end

    def navigation_sections
      Admin::Navigation.visible_sections(self)
    end

    def navigation_path(item)
      Admin::Navigation.resolve_path(item, self)
    end

    def navigation_active?(item)
      path = navigation_path(item)
      return true if path && view_context.current_page?(path)

      item.children.any? { |child| navigation_active?(child) }
    end

    def audit_target_record
      instance_variable_get("@#{controller_name.singularize}")
    end

    def default_audit_metadata
      record = audit_target_record
      return {} unless record.respond_to?(:saved_changes)

      filtered = record.saved_changes.except(*SENSITIVE_AUDIT_KEYS)
      return {} if filtered.empty?

      { changes: filtered }
    end
  end
end
