module Admin
  # 管理画面トップページ。権限に応じた KPI・承認待ち・アラート情報を集約して表示する。
  class DashboardController < BaseController
    def index
      @tenant = current_tenant
      @user_count = @tenant.users.count
      @role_count = @tenant.roles.count
      @onboarding_steps = build_onboarding_steps
      @recent_audit_logs = load_recent_audit_logs

      @kpi                     = build_kpi
      @pending_leave_requests  = load_pending_leave_requests
      @pending_expense_reports = load_pending_expense_reports
      @low_stock_items         = load_low_stock_items
      @expiring_contracts      = load_expiring_contracts
    end

    private

    # ── KPI ──────────────────────────────────────────────────────────────

    def build_kpi
      today      = Date.current
      month_from = today.beginning_of_month
      month_to   = today.end_of_month

      {
        monthly_sales:       monthly_sales(month_from, month_to),
        receivable_balance:  receivable_balance,
        pending_approvals:   pending_approvals_count,
        working_employees:   working_employees_count
      }
    end

    # 今月の請求金額合計（invoices 権限がある場合のみ取得）
    def monthly_sales(from, to)
      return nil unless can?("admin.invoices.read")

      @tenant.invoices
             .where.not(status: "cancelled")
             .where(invoice_date: from..to)
             .sum(:total_amount).to_d
    end

    # 未回収の売掛残高合計（receivables 権限がある場合のみ取得）
    def receivable_balance
      return nil unless can?("admin.receivables.read")

      @tenant.invoices
             .where(status: %w[issued partially_paid])
             .where("balance_amount > 0")
             .sum(:balance_amount).to_d
    end

    # 承認待ち申請数（有給 + 経費の合計）
    def pending_approvals_count
      leave_count   = can?("admin.leave_requests.update")  ? @tenant.leave_requests.where(status: "pending").count : 0
      expense_count = can?("admin.expense_reports.update") ? @tenant.expense_reports.where(status: "pending").count : 0
      leave_count + expense_count
    end

    # 現在出勤中の従業員数（勤怠権限がある場合のみ取得）
    def working_employees_count
      return nil unless can?("admin.attendance_records.read")

      @tenant.attendance_records.where(status: "working").count
    end

    # ── 承認待ち一覧 ─────────────────────────────────────────────────────

    def load_pending_leave_requests
      return [] unless can?("admin.leave_requests.update")

      @tenant.leave_requests
             .includes(:employee)
             .where(status: "pending")
             .ordered_for_admin
             .limit(5)
    end

    def load_pending_expense_reports
      return [] unless can?("admin.expense_reports.update")

      @tenant.expense_reports
             .includes(:employee)
             .where(status: "pending")
             .ordered_for_admin
             .limit(5)
    end

    # ── アラート ─────────────────────────────────────────────────────────

    # 安全在庫を下回っている在庫品目（在庫権限がある場合のみ取得）
    def load_low_stock_items
      return [] unless can?("admin.stock_items.read")

      @tenant.stock_items
             .includes(:product, :warehouse)
             .where("(quantity_on_hand - quantity_reserved) <= safety_stock")
             .order(:id)
             .limit(5)
    end

    # 30 日以内に期限を迎える有効な契約（契約権限がある場合のみ取得）
    def load_expiring_contracts
      return [] unless can?("admin.contracts.read")

      @tenant.contracts
             .where(status: "active")
             .expiring_within(30)
             .order(:ended_on)
             .limit(5)
    end

    # ── オンボーディング・監査ログ ────────────────────────────────────────

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
