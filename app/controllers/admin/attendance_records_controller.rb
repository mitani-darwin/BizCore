module Admin
  class AttendanceRecordsController < BaseController
    before_action :set_attendance_record, only: [ :show, :edit, :update, :clock_out ]
    before_action :set_employee_options, only: [ :index, :new, :create, :edit, :update, :clock_in ]

    def index
      @current_month = selected_month
      @filters = {
        month: @current_month.strftime("%Y-%m"),
        employee_id: search_employee_id,
        status: search_status
      }
      @attendance_records = current_tenant.attendance_records
                                          .includes(:employee, :work_shift)
                                          .for_month(@current_month)
                                          .with_employee(search_employee_id)
                                          .with_status(search_status)
                                          .ordered_for_admin
      @attendance_summary = {
        count: @attendance_records.size,
        working_count: @attendance_records.count(&:working?),
        worked_minutes: @attendance_records.sum(&:worked_minutes),
        overtime_minutes: @attendance_records.sum(&:overtime_minutes)
      }
      @month_working_count = current_tenant.attendance_records.for_month(@current_month).where(status: "working").count
      @month_closed_count  = current_tenant.attendance_records.for_month(@current_month).where(status: "closed").count
      default_clock_in_at = Time.zone.now.change(sec: 0)
      @clock_in_defaults = {
        employee_id: search_employee_id,
        clock_in_at: default_clock_in_at,
        clock_in_on: default_clock_in_at.to_date,
        clock_in_time: default_clock_in_at.strftime("%H:%M")
      }
    end

    def show; end

    def new
      @attendance_record = current_tenant.attendance_records.build(default_attendance_attributes)
    end

    def create
      @attendance_record = current_tenant.attendance_records.build(attendance_record_params)
      @attendance_record.break_minutes_manually_set = attendance_record_break_minutes_provided?

      if @attendance_record.save
        redirect_to admin_attendance_record_path(@attendance_record), notice: "勤怠を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @attendance_record.break_minutes_manually_set = attendance_record_break_minutes_provided?
      if @attendance_record.update(attendance_record_params)
        redirect_to admin_attendance_record_path(@attendance_record), notice: "勤怠を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def clock_in
      employee = current_tenant.employees.find(clock_in_params.fetch(:employee_id))
      clock_in_at = parse_datetime(clock_in_params[:clock_in_at]) || Time.current
      @attendance_record = current_tenant.attendance_records.find_or_initialize_by(employee: employee, work_date: clock_in_at.to_date)
      @attendance_record.tenant = current_tenant
      @attendance_record.employee = employee
      @attendance_record.work_shift ||= employee.work_shifts.find_by(work_date: clock_in_at.to_date)
      @attendance_record.note = clock_in_params[:note] if clock_in_params[:note].present?
      @attendance_record.clock_in!(time: clock_in_at)
      audit!(action_key: required_permission_key, auditable: @attendance_record, metadata: { employee_id: employee.id, clock_in_at: clock_in_at })
      redirect_to admin_attendance_record_path(@attendance_record), notice: "出勤を打刻しました。"
    rescue StandardError => e
      redirect_to admin_attendance_records_path(month: selected_month.strftime("%Y-%m")), alert: "出勤打刻に失敗しました: #{e.message}"
    end

    def clock_out
      clock_out_at = parse_datetime(clock_out_params[:clock_out_at]) || Time.current
      @attendance_record.break_minutes_manually_set = clock_out_params.key?(:break_minutes)
      @attendance_record.assign_attributes(clock_out_params.except(:clock_out_at))
      @attendance_record.clock_out!(time: clock_out_at)
      audit!(action_key: required_permission_key, auditable: @attendance_record, metadata: { clock_out_at: clock_out_at })
      redirect_to admin_attendance_record_path(@attendance_record), notice: "退勤を打刻しました。"
    rescue StandardError => e
      redirect_to admin_attendance_record_path(@attendance_record), alert: "退勤打刻に失敗しました: #{e.message}"
    end

    def close_month
      authorize!("admin.attendance_records.update")
      target_month = selected_month
      result = Attendances::CloseMonth.call(
        tenant: current_tenant,
        month: target_month,
        requested_by: current_admin_user
      )
      audit!(action_key: required_permission_key, auditable: nil,
             metadata: { month: target_month, closed_count: result.closed_count })
      notice = build_close_month_notice(result)
      redirect_to admin_attendance_records_path(month: target_month.strftime("%Y-%m")), notice: notice
    rescue StandardError => e
      redirect_to admin_attendance_records_path(month: selected_month.strftime("%Y-%m")), alert: "月次締めに失敗しました: #{e.message}"
    end

    private

    def build_close_month_notice(result)
      parts = []
      parts << "#{result.closed_count}件を締めました" if result.closed_count > 0
      parts << "#{result.already_closed_count}件は締め済み" if result.already_closed_count > 0
      parts << "#{result.draft_count}件は打刻なし（集計対象外）" if result.draft_count > 0
      parts.any? ? "月次締めを実行しました。#{parts.join('、')}。" : "月次締めを実行しました。対象レコードはありませんでした。"
    end

    def set_attendance_record
      @attendance_record = current_tenant.attendance_records.includes(:employee, :work_shift).find_by(id: params[:id])
      return if @attendance_record

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

    def search_status
      status = params[:status].to_s
      AttendanceRecord.statuses.value?(status) ? status : nil
    end

    def default_attendance_attributes
      employee = current_tenant.employees.find_by(id: params[:employee_id])
      work_date = Date.current
      work_shift = employee&.work_shifts&.find_by(work_date: work_date)
      clock_in_at = Time.zone.now.change(hour: 9, min: 0, sec: 0)
      clock_out_at = Time.zone.now.change(hour: 18, min: 0, sec: 0)

      {
        employee: employee,
        work_shift: work_shift,
        work_date: work_date,
        clock_in_at: clock_in_at,
        clock_out_at: clock_out_at,
        break_minutes: work_shift&.break_minutes || employee&.default_break_minutes || 60
      }
    end

    def attendance_record_params
      permitted = params.require(:attendance_record).permit(
        :employee_id,
        :work_shift_id,
        :work_date,
        :clock_in_at,
        :clock_in_on,
        :clock_in_time,
        :clock_out_at,
        :clock_out_on,
        :clock_out_time,
        :break_minutes,
        :note
      )
      assign_clock_datetime!(permitted, :clock_in)
      assign_clock_datetime!(permitted, :clock_out)
      permitted[:work_date] = infer_work_date(permitted)
      permitted
    end

    def attendance_record_break_minutes_provided?
      params.fetch(:attendance_record, {}).key?(:break_minutes)
    end

    def clock_in_params
      permitted = params.permit(:employee_id, :clock_in_at, :clock_in_on, :clock_in_time, :note)
      assign_clock_datetime!(permitted, :clock_in)
      permitted
    end

    def clock_out_params
      permitted = params.fetch(:attendance_record, {}).permit(:clock_out_at, :clock_out_on, :clock_out_time, :break_minutes, :note)
      assign_clock_datetime!(permitted, :clock_out)
      permitted
    end

    def parse_datetime(raw_value)
      return if raw_value.blank?

      Time.zone.parse(raw_value.to_s)
    rescue ArgumentError
      nil
    end

    def assign_clock_datetime!(params_hash, prefix)
      datetime_key = :"#{prefix}_at"
      date_key = :"#{prefix}_on"
      time_key = :"#{prefix}_time"
      combined = combine_date_and_time(params_hash[date_key], params_hash[time_key], fallback: params_hash[datetime_key])

      params_hash[datetime_key] = combined if combined.present?
      params_hash.delete(date_key)
      params_hash.delete(time_key)
    end

    def combine_date_and_time(date_value, time_value, fallback:)
      return parse_datetime(fallback) if date_value.blank? || time_value.blank?

      Time.zone.parse("#{date_value} #{time_value}")
    rescue ArgumentError
      parse_datetime(fallback)
    end

    def infer_work_date(params_hash)
      return params_hash[:work_date] if params_hash[:work_date].present?
      return params_hash[:clock_in_at].to_date if params_hash[:clock_in_at].present?
      return params_hash[:clock_out_at].to_date if params_hash[:clock_out_at].present?

      nil
    end
  end
end
