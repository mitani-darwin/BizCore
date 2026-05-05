class WorkShift < ApplicationRecord
  STATUSES = {
    scheduled: "scheduled",
    completed: "completed",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :employee

  has_one :attendance_record, dependent: :nullify

  enum :status, STATUSES

  scope :for_month, lambda { |month|
    month.present? ? where(work_date: month.beginning_of_month..month.end_of_month) : all
  }
  scope :with_employee, ->(employee_id) { employee_id.present? ? where(employee_id: employee_id) : all }
  scope :ordered_for_admin, -> { order(work_date: :desc, start_time: :asc, id: :desc) }

  validates :work_date, :start_time, :end_time, :status, presence: true
  validates :break_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :work_date, uniqueness: { scope: [ :tenant_id, :employee_id ] }
  validate :tenant_consistency
  validate :end_time_must_be_after_start_time

  before_validation :set_defaults

  def scheduled_minutes
    return 0 if start_time.blank? || end_time.blank?

    duration_minutes = (((end_time.to_i - start_time.to_i) / 60) - break_minutes.to_i)
    [ duration_minutes, 0 ].max
  end

  def title
    "#{employee.name} #{work_date}"
  end

  private

  def set_defaults
    self.status ||= "scheduled"
    self.break_minutes ||= employee&.default_break_minutes || 60
  end

  def tenant_consistency
    return if tenant_id.blank? || employee.blank?

    errors.add(:tenant, "と従業員の所属が一致しません") if tenant_id != employee.tenant_id
  end

  def end_time_must_be_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "は開始時刻より後である必要があります")
  end
end
