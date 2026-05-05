module Admin
  class EmployeesController < BaseController
    before_action :set_employee, only: [ :show, :edit, :update ]

    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        employment_type: search_employment_type
      }
      @employees = current_tenant.employees
                                 .includes(:attendance_records, :leave_requests, payroll_entries: :payroll_run)
                                 .search(search_keyword)
                                 .with_status(search_status)
                                 .with_employment_type(search_employment_type)
                                 .ordered_for_admin
      @employee_summary = {
        count: @employees.size,
        active_count: @employees.count(&:active?),
        hourly_count: @employees.count(&:employment_type_hourly?),
        total_paid_leave_balance: @employees.sum { |employee| employee.remaining_paid_leave_days }
      }
    end

    def show
      month_range = selected_month.beginning_of_month..selected_month.end_of_month
      @current_month = selected_month
      @current_month_shifts = @employee.work_shifts.where(work_date: month_range).ordered_for_admin.limit(10)
      @current_month_attendances = @employee.attendance_records.where(work_date: month_range).ordered_for_admin.limit(10)
      @current_month_leave_requests = @employee.leave_requests.for_month(selected_month).ordered_for_admin.limit(10)
      @recent_payroll_entries = @employee.payroll_entries.includes(:payroll_run).order(id: :desc).limit(6)
      @monthly_summary = {
        worked_minutes: @employee.attendance_records.where(work_date: month_range, status: "closed").sum(:worked_minutes),
        overtime_minutes: @employee.attendance_records.where(work_date: month_range, status: "closed").sum(:overtime_minutes),
        paid_leave_days: @employee.leave_requests.approved_paid_leave.to_a.sum { |leave_request| leave_request.days_within(month_range) }
      }
    end

    def new
      @employee = current_tenant.employees.build(default_employee_attributes)
    end

    def create
      @employee = current_tenant.employees.build(employee_params)

      if @employee.save
        redirect_to admin_employee_path(@employee), notice: "従業員を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @employee.update(employee_params)
        redirect_to admin_employee_path(@employee), notice: "従業員を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_employee
      @employee = current_tenant.employees.find_by(id: params[:id])
      return if @employee

      render_not_found and return false
    end

    def selected_month
      value = params[:month].presence || Date.current.strftime("%Y-%m")
      Date.strptime(value, "%Y-%m")
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Employee.statuses.value?(status) ? status : nil
    end

    def search_employment_type
      employment_type = params[:employment_type].to_s
      Employee.employment_types.value?(employment_type) ? employment_type : nil
    end

    def default_employee_attributes
      {
        joined_on: Date.current,
        status: "active",
        employment_type: "hourly",
        overtime_rate_multiplier: 1.25,
        standard_daily_minutes: 480,
        default_break_minutes: 60,
        paid_leave_granted_days: 10
      }
    end

    def employee_params
      params.require(:employee).permit(
        :employee_code,
        :name,
        :status,
        :employment_type,
        :joined_on,
        :base_hourly_wage,
        :base_monthly_salary,
        :overtime_rate_multiplier,
        :standard_daily_minutes,
        :default_break_minutes,
        :paid_leave_granted_days,
        :tel,
        :email,
        :note
      )
    end
  end
end
