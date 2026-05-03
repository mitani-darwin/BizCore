class LeaveRequest < ApplicationRecord
  LEAVE_TYPES = {
    paid_leave: "paid_leave",
    special_leave: "special_leave"
  }.freeze

  STATUSES = {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }.freeze

  belongs_to :tenant
  belongs_to :employee

  enum :leave_type, LEAVE_TYPES, prefix: true
  enum :status, STATUSES, prefix: true

  scope :for_month, lambda { |month|
    return all if month.blank?

    where("start_date <= ? AND end_date >= ?", month.end_of_month, month.beginning_of_month)
  }
  scope :with_employee, ->(employee_id) { employee_id.present? ? where(employee_id: employee_id) : all }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :approved_paid_leave, -> { where(status: "approved", leave_type: "paid_leave") }
  scope :ordered_for_admin, -> { order(start_date: :desc, id: :desc) }

  validates :start_date, :end_date, :days_count, :leave_type, :status, presence: true
  validates :days_count, numericality: { greater_than: 0 }
  validate :tenant_consistency
  validate :end_date_must_not_be_before_start_date
  validate :no_attendance_overlap_when_approved

  before_validation :set_defaults
  before_validation :calculate_days_count

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected")
  end

  def title
    "#{employee.name} #{start_date}"
  end

  def calendar_days
    return 0 if start_date.blank? || end_date.blank?

    (end_date - start_date).to_i + 1
  end

  def overlap_days_with(range)
    return 0 if start_date.blank? || end_date.blank?

    overlap_start = [start_date, range.begin].max
    overlap_end = [end_date, range.end].min
    return 0 if overlap_end < overlap_start

    (overlap_end - overlap_start).to_i + 1
  end

  def days_within(range)
    overlap_days = overlap_days_with(range)
    return 0.to_d if overlap_days <= 0
    return days_count.to_d if calendar_days <= 1

    (days_count.to_d / calendar_days.to_d) * overlap_days
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.leave_type ||= "paid_leave"
  end

  def calculate_days_count
    return if start_date.blank? || end_date.blank?
    return if days_count.to_d.positive? && changed.exclude?("start_date") && changed.exclude?("end_date")

    self.days_count = ((end_date - start_date).to_i + 1).to_d
  end

  def tenant_consistency
    return if tenant_id.blank? || employee.blank?

    errors.add(:tenant, "と従業員の所属が一致しません") if tenant_id != employee.tenant_id
  end

  def end_date_must_not_be_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "は開始日以降である必要があります")
  end

  def no_attendance_overlap_when_approved
    return unless status_approved?
    return if employee.blank? || start_date.blank? || end_date.blank?
    return unless employee.attendance_records.where(work_date: start_date..end_date).exists?

    errors.add(:base, "承認済みの有給期間に勤怠実績が存在します")
  end
end
