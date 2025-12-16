module Admin
  class AuditLogsController < BaseController
    def index
      logs = scope_logs.recent
      logs = logs.page(params[:page]).per(50) if logs.respond_to?(:page)
      @audit_logs = logs
    end

    def show
      @audit_log = scope_logs.find(params[:id])
    end

    private

    def scope_logs
      AuditLog.for_tenant(Current.tenant)
    end
  end
end
