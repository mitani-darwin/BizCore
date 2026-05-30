module Admin
  # 監査ログの閲覧専用コントローラ。書き込みは BaseController が自動で行う。
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
