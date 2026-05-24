class Employee < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    active: "active",
    inactive: "inactive"
  }.freeze

  EMPLOYMENT_TYPES = {
    hourly: "hourly",
    salaried: "salaried"
  }.freeze

  belongs_to :tenant

  has_one :user, dependent: :nullify
  has_many :work_shifts, dependent: :restrict_with_exception
  has_many :attendance_records, dependent: :restrict_with_exception
  has_many :leave_requests, dependent: :restrict_with_exception
  has_many :payroll_entries, dependent: :restrict_with_exception
  has_many :daily_reports, dependent: :destroy

  enum :status, STATUSES
  enum :employment_type, EMPLOYMENT_TYPES, prefix: true

  generates_document_number :employee_code, prefix: "EMP"

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where(
      <<~SQL.squish,
        employee_code LIKE :pattern OR
        name LIKE :pattern OR
        email LIKE :pattern OR
        tel LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :with_employment_type, ->(employment_type) { employment_type.present? ? where(employment_type: employment_type) : all }
  scope :ordered_for_admin, -> { order(Arel.sql("CASE WHEN status = 'active' THEN 0 ELSE 1 END"), :employee_code, :id) }

  validates :employee_code, :name, :status, :employment_type, presence: true
  validates :employee_code, uniqueness: { scope: :tenant_id }
  validates :base_hourly_wage, :base_monthly_salary, :overtime_rate_multiplier, numericality: { greater_than_or_equal_to: 0 }
  validates :standard_daily_minutes, :default_break_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :paid_leave_granted_days, numericality: { greater_than_or_equal_to: 0 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :compensation_must_be_set

  before_validation :set_defaults

  def remaining_paid_leave_days(as_of: Date.current)
    paid_leave_granted_days.to_d - approved_paid_leave_days(as_of: as_of)
  end

  def approved_paid_leave_days(as_of: Date.current)
    leave_requests.approved_paid_leave.where("start_date <= ?", as_of).sum(:days_count).to_d
  end

  def effective_hourly_rate
    return base_hourly_wage.to_d if base_hourly_wage.to_d.positive?
    return 0.to_d if standard_daily_minutes.to_i <= 0 || base_monthly_salary.to_d <= 0

    monthly_work_minutes = standard_daily_minutes.to_d * 20
    return 0.to_d if monthly_work_minutes <= 0

    base_monthly_salary.to_d / (monthly_work_minutes / 60)
  end

  def standard_daily_hours
    standard_daily_minutes.to_d / 60
  end

  def title
    "#{employee_code} #{name}"
  end

  private

  def set_defaults
    self.status ||= "active"
    self.employment_type ||= "hourly"
    self.joined_on ||= Date.current
    self.overtime_rate_multiplier ||= 1.25
    self.standard_daily_minutes ||= 480
    self.default_break_minutes ||= 60
    self.paid_leave_granted_days ||= 10
  end

  def compensation_must_be_set
    if employment_type_hourly? && base_hourly_wage.to_d <= 0
      errors.add(:base_hourly_wage, "は時給制では必須です")
    end

    if employment_type_salaried? && base_monthly_salary.to_d <= 0
      errors.add(:base_monthly_salary, "は月給制では必須です")
    end
  end
end
