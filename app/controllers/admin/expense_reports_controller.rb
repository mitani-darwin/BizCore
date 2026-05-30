module Admin
  # 経費精算申請の CRUD・承認・却下を管理する。
  # approve / reject は ExpenseReport モデルのメソッドを直接呼び出す。
  class ExpenseReportsController < BaseController
    before_action :set_expense_report, only: %i[show edit update approve reject]
    before_action :set_employee_options, only: %i[index new create edit update]

    def index
      @current_month = selected_month
      @filters = {
        month: @current_month.strftime("%Y-%m"),
        employee_id: search_employee_id,
        status: search_status
      }
      query = current_tenant.expense_reports
                            .includes(:employee)
                            .for_month(@current_month)
                            .with_employee(search_employee_id)
                            .with_status(search_status)
                            .ordered_for_admin
      @summary = {
        count: query.size,
        pending_count: query.count(&:status_pending?),
        total_amount: query.select(&:status_approved?).sum(&:amount)
      }
      @pagy, @expense_reports = pagy(query)
    end

    def show; end

    def new
      @expense_report = current_tenant.expense_reports.build(
        expensed_on: Date.current,
        employee_id: params[:employee_id]
      )
    end

    def create
      @expense_report = current_tenant.expense_reports.build(expense_report_params)

      if @expense_report.save
        redirect_to admin_expense_report_path(@expense_report), notice: "経費申請を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @expense_report.update(expense_report_params)
        redirect_to admin_expense_report_path(@expense_report), notice: "経費申請を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      @expense_report.approve!
      audit!(action_key: required_permission_key, auditable: @expense_report, metadata: { status: "approved" })
      redirect_to admin_expense_report_path(@expense_report), notice: "経費申請を承認しました。"
    rescue StandardError => e
      redirect_to admin_expense_report_path(@expense_report), alert: "承認に失敗しました: #{e.message}"
    end

    def reject
      @expense_report.reject!
      audit!(action_key: required_permission_key, auditable: @expense_report, metadata: { status: "rejected" })
      redirect_to admin_expense_report_path(@expense_report), notice: "経費申請を却下しました。"
    rescue StandardError => e
      redirect_to admin_expense_report_path(@expense_report), alert: "却下に失敗しました: #{e.message}"
    end

    private

    def set_expense_report
      @expense_report = current_tenant.expense_reports.includes(:employee).find_by(id: params[:id])
      return if @expense_report

      render_not_found and return false
    end

    def set_employee_options
      @employee_options = current_tenant.employees.ordered_for_admin
    end

    def selected_month
      value = params[:month].presence || Date.current.strftime("%Y-%m")
      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    def search_employee_id
      id = params[:employee_id].to_i
      id.positive? ? id : nil
    end

    def search_status
      status = params[:status].to_s
      ExpenseReport.statuses.value?(status) ? status : nil
    end

    def expense_report_params
      params.require(:expense_report).permit(
        :employee_id,
        :expensed_on,
        :category,
        :description,
        :amount,
        :purpose,
        :note
      )
    end
  end
end
