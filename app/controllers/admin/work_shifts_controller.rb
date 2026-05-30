module Admin
  # シフトの CRUD とグリッド入力画面を管理する。
  # grid アクションは月×従業員のマトリクスで一括入力できる専用レイアウトを提供する。
  class WorkShiftsController < BaseController
    before_action :set_work_shift, only: [ :show, :edit, :update, :destroy ]
    before_action :set_employee_options, only: [ :index, :new, :create, :edit, :update ]

    def grid
      @current_month = selected_month
      @grid_month_param = @current_month.strftime("%Y-%m")
      @dates = (@current_month.beginning_of_month..@current_month.end_of_month).to_a
      @employees = current_tenant.employees.ordered_for_admin
      shifts = current_tenant.work_shifts
                             .for_month(@current_month)
                             .includes(:employee)
      @shift_map = shifts.index_by { |s| [ s.employee_id, s.work_date ] }
    end

    def index
      @current_month = selected_month
      @filters = {
        month: @current_month.strftime("%Y-%m"),
        employee_id: search_employee_id
      }
      query = current_tenant.work_shifts
                            .includes(:employee, :attendance_record)
                            .for_month(@current_month)
                            .with_employee(search_employee_id)
                            .ordered_for_admin
      @shift_summary = {
        count: query.size,
        scheduled_minutes: query.sum(&:scheduled_minutes),
        completed_count: query.count(&:completed?)
      }
      @pagy, @work_shifts = pagy(query)
    end

    def show; end

    def new
      if params[:from_grid].present? && params[:employee_id].present? && params[:work_date].present?
        existing = current_tenant.work_shifts.find_by(
          employee_id: params[:employee_id],
          work_date: params[:work_date]
        )
        if existing
          @work_shift = existing
          render :edit and return
        end
      end
      @work_shift = current_tenant.work_shifts.build(default_work_shift_attributes)
    end

    def create
      @work_shift = current_tenant.work_shifts.build(work_shift_params)

      if @work_shift.save
        if params[:from_grid].present?
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                "shift_cell_#{@work_shift.employee_id}_#{@work_shift.work_date}",
                partial: "grid_cell",
                locals: { shift: @work_shift, employee: @work_shift.employee, date: @work_shift.work_date, grid_month_param: params[:from_grid] }
              )
            end
            format.html { redirect_to grid_admin_work_shifts_path(month: params[:from_grid]) }
          end
        else
          redirect_to admin_work_shift_path(@work_shift), notice: "シフトを作成しました。"
        end
      else
        render :new, status: :unprocessable_entity, layout: params[:from_grid].blank?
      end
    end

    def edit; end

    def destroy
      authorize!("admin.work_shifts.delete")
      employee_id = @work_shift.employee_id
      work_date   = @work_shift.work_date
      @work_shift.destroy!

      if params[:from_grid].present?
        respond_to do |format|
          format.turbo_stream do
            employee = current_tenant.employees.find_by(id: employee_id)
            render turbo_stream: turbo_stream.replace(
              "shift_cell_#{employee_id}_#{work_date}",
              partial: "grid_cell",
              locals: { shift: nil, employee: employee, date: work_date, grid_month_param: params[:from_grid] }
            )
          end
          format.html { redirect_to grid_admin_work_shifts_path(month: params[:from_grid]), notice: "シフトを削除しました。" }
        end
      else
        redirect_to admin_work_shifts_path(month: work_date.strftime("%Y-%m")), notice: "シフトを削除しました。"
      end
    end

    def update
      if @work_shift.update(work_shift_params)
        if params[:from_grid].present?
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                "shift_cell_#{@work_shift.employee_id}_#{@work_shift.work_date}",
                partial: "grid_cell",
                locals: { shift: @work_shift, employee: @work_shift.employee, date: @work_shift.work_date, grid_month_param: params[:from_grid] }
              )
            end
            format.html { redirect_to grid_admin_work_shifts_path(month: params[:from_grid]) }
          end
        else
          redirect_to admin_work_shift_path(@work_shift), notice: "シフトを更新しました。"
        end
      else
        render :edit, status: :unprocessable_entity, layout: params[:from_grid].blank?
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
        work_date: params[:work_date].presence || Date.current,
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
