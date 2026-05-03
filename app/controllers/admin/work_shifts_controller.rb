module Admin
  class WorkShiftsController < BaseController
    before_action :set_work_shift, only: [:show, :edit, :update]
    before_action :set_employee_options, only: [:index, :new, :create, :edit, :update]

    def index
      @current_month = selected_month
      @filters = {
        month: @current_month.strftime("%Y-%m"),
        employee_id: search_employee_id
      }
      @work_shifts = current_tenant.work_shifts
                                   .includes(:employee, :attendance_record)
                                   .for_month(@current_month)
                                   .with_employee(search_employee_id)
                                   .ordered_for_admin
      @shift_summary = {
        count: @work_shifts.size,
        scheduled_minutes: @work_shifts.sum(&:scheduled_minutes),
        completed_count: @work_shifts.count(&:completed?)
      }
    end

    def show; end

    def new
      @work_shift = current_tenant.work_shifts.build(default_work_shift_attributes)
    end

    def create
      @work_shift = current_tenant.work_shifts.build(work_shift_params)

      if @work_shift.save
        redirect_to admin_work_shift_path(@work_shift), notice: "シフトを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @work_shift.update(work_shift_params)
        redirect_to admin_work_shift_path(@work_shift), notice: "シフトを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_work_shift
      @work_shift = current_tenant.work_shifts.includes(:employee, :attendance_record).find_by(id: params[:id])
      return if @work_shift

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
      employee_id = params[:employee_id].to_i
      employee_id.positive? ? employee_id : nil
    end

    def default_work_shift_attributes
      {
        employee_id: params[:employee_id],
        work_date: Date.current,
        start_time: Time.zone.parse("09:00"),
        end_time: Time.zone.parse("18:00"),
        break_minutes: 60,
        status: "scheduled"
      }
    end

    def work_shift_params
      params.require(:work_shift).permit(
        :employee_id,
        :work_date,
        :start_time,
        :end_time,
        :break_minutes,
        :status,
        :note
      )
    end
  end
end
