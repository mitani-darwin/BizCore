module Admin
  class AuditLogsController < BaseController
    def index
      @pagy, @audit_logs = pagy(scope_logs.recent)
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
