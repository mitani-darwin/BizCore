class SelfAttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_current_tenant!
  before_action :ensure_current_employee!

  def show
    @selected_date = selected_date
    @attendance_record = current_employee.attendance_records.includes(:work_shift).find_by(work_date: @selected_date)
    @working_attendance_record = current_employee.attendance_records.where(status: "working").order(clock_in_at: :desc, id: :desc).first
    @target_attendance_record = @working_attendance_record || @attendance_record
    @today_work_shift = current_employee.work_shifts.find_by(work_date: @selected_date)
    @recent_attendance_records = current_employee.attendance_records.includes(:work_shift).order(work_date: :desc, id: :desc).limit(7)
    default_clock_in_at = Time.zone.now.change(sec: 0)
    default_clock_out_at = Time.zone.now.change(sec: 0)
    @clock_in_defaults = {
      clock_in_on: default_clock_in_at.to_date,
      clock_in_time: default_clock_in_at.strftime("%H:%M")
    }
    @clock_out_defaults = {
      clock_out_on: default_clock_out_at.to_date,
      clock_out_time: default_clock_out_at.strftime("%H:%M")
    }
    @admin_entry_path = first_admin_path
  end

  def clock_in
    clock_in_at = parse_datetime(clock_in_params[:clock_in_at]) || Time.current
    attendance_record = current_tenant.attendance_records.find_or_initialize_by(employee: current_employee, work_date: clock_in_at.to_date)
    attendance_record.tenant = current_tenant
    attendance_record.employee = current_employee
    attendance_record.work_shift ||= current_employee.work_shifts.find_by(work_date: clock_in_at.to_date)
    attendance_record.note = clock_in_params[:note] if clock_in_params[:note].present?
    attendance_record.clock_in!(time: clock_in_at)
    redirect_to my_attendance_path(date: clock_in_at.to_date), notice: "出勤を打刻しました。"
  rescue StandardError => e
    redirect_to my_attendance_path(date: selected_date), alert: "出勤打刻に失敗しました: #{e.message}"
  end

  def clock_out
    attendance_record = attendance_record_for_clock_out!
    attendance_record.break_minutes_manually_set = clock_out_params.key?(:break_minutes)
    attendance_record.assign_attributes(clock_out_params.except(:clock_out_at, :attendance_record_id))
    clock_out_at = parse_datetime(clock_out_params[:clock_out_at]) || Time.current
    attendance_record.clock_out!(time: clock_out_at)
    redirect_to my_attendance_path(date: attendance_record.work_date), notice: "退勤を打刻しました。"
  rescue StandardError => e
    redirect_to my_attendance_path(date: selected_date), alert: "退勤打刻に失敗しました: #{e.message}"
  end

  private

  def ensure_current_tenant!
    return if current_tenant.present?

    render_not_found
  end

  def ensure_current_employee!
    return if current_employee.present?

    render_not_found
  end

  def selected_date
    return Date.current if params[:date].blank?

    Date.parse(params[:date])
  rescue ArgumentError
    Date.current
  end

  def clock_in_params
    permitted = params.permit(:clock_in_at, :clock_in_on, :clock_in_time, :note)
    assign_clock_datetime!(permitted, :clock_in)
    permitted
  end

  def clock_out_params
    permitted = params.fetch(:attendance_record, {}).permit(:attendance_record_id, :clock_out_at, :clock_out_on, :clock_out_time, :break_minutes, :note)
    assign_clock_datetime!(permitted, :clock_out)
    permitted
  end

  def attendance_record_for_clock_out!
    if clock_out_params[:attendance_record_id].present?
      current_employee.attendance_records.find(clock_out_params[:attendance_record_id])
    else
      current_employee.attendance_records.where(status: "working").order(clock_in_at: :desc, id: :desc).first || raise(ActiveRecord::RecordNotFound, "勤務中の打刻が見つかりません")
    end
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

  def parse_datetime(raw_value)
    return if raw_value.blank?

    Time.zone.parse(raw_value.to_s)
  rescue ArgumentError
    nil
  end

  def first_admin_path
    Admin::Navigation.visible_sections(self).flat_map(&:items).map { |item| Admin::Navigation.resolve_path(item, self) }.compact.first
  end
end
