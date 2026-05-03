class AttendanceRecord < ApplicationRecord
  attr_accessor :break_minutes_manually_set

  STATUSES = {
    draft: "draft",
    working: "working",
    closed: "closed"
  }.freeze

  belongs_to :tenant
  belongs_to :employee
  belongs_to :work_shift, optional: true

  enum :status, STATUSES

  scope :for_month, lambda { |month|
    month.present? ? where(work_date: month.beginning_of_month..month.end_of_month) : all
  }
  scope :with_employee, ->(employee_id) { employee_id.present? ? where(employee_id: employee_id) : all }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :ordered_for_admin, -> { order(work_date: :desc, id: :desc) }

  validates :work_date, :status, presence: true
  validates :work_date, uniqueness: { scope: [:tenant_id, :employee_id] }
  validates :break_minutes, :worked_minutes, :overtime_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency
  validate :clock_out_must_be_after_clock_in
  validate :cannot_overlap_approved_leave

  before_validation :assign_shift_from_employee
  before_validation :assign_inferred_break_minutes
  before_validation :set_defaults
  before_validation :calculate_worked_minutes
  before_validation :calculate_overtime_minutes
  before_validation :set_status_from_times

  def clock_in!(time: Time.current)
    raise ArgumentError, "既に出勤打刻されています" if clock_in_at.present?

    update!(clock_in_at: time, work_date: time.to_date)
  end

  def clock_out!(time: Time.current)
    raise ArgumentError, "出勤打刻がありません" if clock_in_at.blank?
    raise ArgumentError, "既に退勤打刻されています" if clock_out_at.present?

    update!(clock_out_at: time)
  end

  def regular_worked_minutes
    [worked_minutes.to_i - overtime_minutes.to_i, 0].max
  end

  def title
    "#{employee.name} #{work_date}"
  end

  private

  def assign_inferred_break_minutes
    return if break_minutes_manually_set
    return unless new_record? || will_save_change_to_work_shift_id? || break_minutes.to_i <= 0

    inferred_break_minutes = work_shift&.break_minutes || employee&.default_break_minutes
    self.break_minutes = inferred_break_minutes unless inferred_break_minutes.nil?
  end

  def set_defaults
    self.work_date ||= clock_in_at&.to_date || Date.current
    self.break_minutes = 0 if break_minutes.nil?
    self.status ||= "draft"
  end

  def assign_shift_from_employee
    return unless employee && work_date
    return if work_shift.present?

    self.work_shift = employee.work_shifts.find_by(work_date: work_date)
  end

  def calculate_worked_minutes
    self.worked_minutes =
      if clock_in_at.present? && clock_out_at.present?
        [(((clock_out_at - clock_in_at) / 60).to_i - break_minutes.to_i), 0].max
      else
        0
      end
  end

  def calculate_overtime_minutes
    scheduled_minutes = work_shift&.scheduled_minutes || employee&.standard_daily_minutes.to_i
    self.overtime_minutes = [worked_minutes.to_i - scheduled_minutes.to_i, 0].max
  end

  def set_status_from_times
    self.status =
      if clock_out_at.present?
        "closed"
      elsif clock_in_at.present?
        "working"
      else
        "draft"
      end
  end

  def tenant_consistency
    return if tenant_id.blank? || employee.blank?

    mismatch = tenant_id != employee.tenant_id
    mismatch ||= work_shift.present? && (tenant_id != work_shift.tenant_id || employee_id != work_shift.employee_id)
    errors.add(:tenant, "と従業員の所属が一致しません") if mismatch
  end

  def clock_out_must_be_after_clock_in
    return if clock_in_at.blank? || clock_out_at.blank?
    return if clock_out_at > clock_in_at

    errors.add(:clock_out_at, "は出勤時刻より後である必要があります")
  end

  def cannot_overlap_approved_leave
    return if employee.blank? || work_date.blank?
    return unless employee.leave_requests.approved_paid_leave.exists?(["start_date <= ? AND end_date >= ?", work_date, work_date])

    errors.add(:work_date, "は承認済みの有給と重複しています")
  end
end
