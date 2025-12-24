module Admin
  class DashboardController < BaseController
    def index
      @tenant = current_tenant
      @user_count = @tenant.users.count
      @role_count = @tenant.roles.count
      @onboarding_steps = build_onboarding_steps
      @recent_audit_logs = load_recent_audit_logs
    end

    private

    def build_onboarding_steps
      [
        {
          id: :users,
          label: "ユーザーを追加する",
          done: @user_count.positive?,
          path: new_admin_user_path,
          permission_key: "admin.users.create"
        },
        {
          id: :roles,
          label: "ロールを整備する",
          done: @role_count.positive?,
          path: new_admin_role_path,
          permission_key: "admin.roles.create"
        },
        {
          id: :permissions,
          label: "権限定義を確認する",
          done: Permission.exists?,
          path: admin_permissions_path,
          permission_key: "admin.permissions.read"
        },
        {
          id: :authorizations,
          label: "権限割当を更新する",
          done: RolePermission.exists?,
          path: admin_authorization_path,
          permission_key: "admin.authorizations.update"
        }
      ]
    end

    def load_recent_audit_logs
      return [] unless can?("admin.audit_logs.read")

      AuditLog.for_tenant(@tenant).recent.limit(5)
    end
  end
end
