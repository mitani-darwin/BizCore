module Admin
  module WorkforceHelper
    include Admin::OrderingHelper

    EMPLOYEE_STATUS_OPTIONS = [
      [ "在籍", "active" ],
      [ "停止", "inactive" ]
    ].freeze

    EMPLOYMENT_TYPE_OPTIONS = [
      [ "時給制", "hourly" ],
      [ "月給制", "salaried" ]
    ].freeze

    WORK_SHIFT_STATUS_OPTIONS = [
      [ "予定", "scheduled" ],
      [ "完了", "completed" ],
      [ "取消", "cancelled" ]
    ].freeze

    ATTENDANCE_STATUS_OPTIONS = [
      [ "未打刻", "draft" ],
      [ "勤務中", "working" ],
      [ "勤務確定", "closed" ]
    ].freeze

    LEAVE_TYPE_OPTIONS = [
      [ "有給", "paid_leave" ],
      [ "特別休暇", "special_leave" ]
    ].freeze

    LEAVE_STATUS_OPTIONS = [
      [ "申請中", "pending" ],
      [ "承認済み", "approved" ],
      [ "却下", "rejected" ]
    ].freeze

    def employee_status_options
      EMPLOYEE_STATUS_OPTIONS
    end

    def employment_type_options
      EMPLOYMENT_TYPE_OPTIONS
    end

    def work_shift_status_options
      WORK_SHIFT_STATUS_OPTIONS
    end

    def attendance_status_options
      ATTENDANCE_STATUS_OPTIONS
    end

    def leave_type_options
      LEAVE_TYPE_OPTIONS
    end

    def leave_status_options
      LEAVE_STATUS_OPTIONS
    end

    def jp_datetime(value)
      return "-" if value.blank?

      value.in_time_zone.strftime("%Y/%m/%d %H:%M")
    end

    def hhmm(value)
      return "-" if value.blank?

      value.strftime("%H:%M")
    end

    def minutes_to_hours(minutes)
      hours = minutes.to_i / 60.0
      format("%.2f時間", hours)
    end

    def signed_minutes(minutes)
      "#{minutes.to_i.positive? ? '+' : ''}#{minutes.to_i}分"
    end

    def employee_status_label(status)
      case status.to_s
      when "active" then "在籍"
      when "inactive" then "停止"
      else status.to_s
      end
    end

    def employee_status_badge(employee)
      tone = employee.active? ? "emerald" : "slate"

      status_badge(employee_status_label(employee.status), tone)
    end

    def employment_type_label(employment_type)
      case employment_type.to_s
      when "hourly" then "時給制"
      when "salaried" then "月給制"
      else employment_type.to_s
      end
    end

    def employment_type_badge(employee)
      tone = employee.employment_type_hourly? ? "sky" : "violet"

      status_badge(employment_type_label(employee.employment_type), tone)
    end

    def work_shift_status_badge(work_shift)
      label, tone = case work_shift.status
      when "scheduled" then [ "予定", "sky" ]
      when "completed" then [ "完了", "emerald" ]
      when "cancelled" then [ "取消", "rose" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end

    def attendance_status_badge(attendance_record)
      label, tone = case attendance_record.status
      when "draft" then [ "未打刻", "slate" ]
      when "working" then [ "勤務中", "amber" ]
      when "closed" then [ "勤務確定", "emerald" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end

    def attendance_status_label(status)
      case status.to_s
      when "draft" then "未打刻"
      when "working" then "勤務中"
      when "closed" then "勤務確定"
      else status.to_s
      end
    end

    def leave_type_label(leave_type)
      case leave_type.to_s
      when "paid_leave" then "有給"
      when "special_leave" then "特別休暇"
      else leave_type.to_s
      end
    end

    def leave_status_badge(leave_request)
      label, tone = case leave_request.status
      when "pending" then [ "申請中", "amber" ]
      when "approved" then [ "承認済み", "emerald" ]
      when "rejected" then [ "却下", "rose" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end

    def payroll_run_status_badge(payroll_run)
      label, tone = case payroll_run.status
      when "generated" then [ "計算済み", "sky" ]
      when "confirmed" then [ "確定", "emerald" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end
  end
end
