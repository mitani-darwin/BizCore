module Admin
  class PayrollRunsController < BaseController
    before_action :set_payroll_run, only: [ :show, :confirm ]

    def index
      @current_month = selected_month
      @payroll_runs = current_tenant.payroll_runs.includes(payroll_entries: :employee).ordered_for_admin
      @payroll_summary = {
        count: @payroll_runs.size,
        latest_total_gross_pay: @payroll_runs.first&.total_gross_pay.to_d,
        latest_employee_count: @payroll_runs.first&.employee_count.to_i
      }
    end

    def show
      @payroll_entries = @payroll_run.payroll_entries.joins(:employee).includes(:employee).order("employees.employee_code ASC, payroll_entries.id ASC")
    end

    def confirm
      authorize!("admin.payroll_runs.update")
      @payroll_run.confirm!(confirmed_by: current_admin_user)
      audit!(action_key: required_permission_key, auditable: @payroll_run, metadata: { payroll_month: @payroll_run.payroll_month })
      redirect_to admin_payroll_run_path(@payroll_run), notice: "給与計算を確定しました。"
    rescue StandardError => e
      redirect_to admin_payroll_run_path(@payroll_run), alert: "確定に失敗しました: #{e.message}"
    end

    def generate
      payroll_month = parse_month_value(params[:payroll_month]) || selected_month
      @payroll_run = Payrolls::GenerateRun.call(
        tenant: current_tenant,
        payroll_month: payroll_month,
        requested_by: current_admin_user,
        note: params[:note].presence
      )
      audit!(action_key: required_permission_key, auditable: @payroll_run, metadata: { payroll_month: payroll_month.beginning_of_month })
      redirect_to admin_payroll_run_path(@payroll_run), notice: "勤怠・残業・有給を給与へ自動反映しました。"
    rescue StandardError => e
      redirect_to admin_payroll_runs_path(month: selected_month.strftime("%Y-%m")), alert: "給与反映に失敗しました: #{e.message}"
    end

    private

    def set_payroll_run
      @payroll_run = current_tenant.payroll_runs.includes(payroll_entries: :employee).find_by(id: params[:id])
      return if @payroll_run

      render_not_found and return false
    end

    def selected_month
      parse_month_value(params[:month]) || Date.current.beginning_of_month
    end

    def parse_month_value(value)
      return if value.blank?

      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      nil
    end
  end
end
