class ExpenseReport < ApplicationRecord
  CATEGORIES = {
    transportation: "transportation",
    entertainment:  "entertainment",
    supplies:       "supplies",
    communication:  "communication",
    other:          "other"
  }.freeze

  STATUSES = {
    pending:  "pending",
    approved: "approved",
    rejected: "rejected"
  }.freeze

  belongs_to :tenant
  belongs_to :employee

  enum :category, CATEGORIES, prefix: true
  enum :status,   STATUSES,   prefix: true

  scope :for_month, lambda { |month|
    return all if month.blank?

    where(expensed_on: month.beginning_of_month..month.end_of_month)
  }
  scope :with_employee, ->(employee_id) { employee_id.present? ? where(employee_id: employee_id) : all }
  scope :with_status,   ->(status)      { status.present? ? where(status: status) : all }
  scope :ordered_for_admin, -> { order(expensed_on: :desc, id: :desc) }

  validates :expensed_on, :category, :description, :status, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validate :tenant_consistency

  before_validation :set_defaults

  def approve!
    update!(status: "approved")
  end

  def reject!
    update!(status: "rejected")
  end

  def title
    "#{employee.name} #{expensed_on}"
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.category ||= "other"
  end

  def tenant_consistency
    return if tenant_id.blank? || employee.blank?

    errors.add(:tenant, "と従業員の所属が一致しません") if tenant_id != employee.tenant_id
  end
end
