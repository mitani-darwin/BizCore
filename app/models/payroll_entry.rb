class PayrollEntry < ApplicationRecord
  belongs_to :tenant
  belongs_to :payroll_run
  belongs_to :employee

  validates :worked_minutes, :overtime_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :paid_leave_days, :base_pay, :overtime_pay, :paid_leave_pay, :gross_pay, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: :payroll_run_id }
  validate :tenant_consistency

  def title
    employee.name
  end

  private

  def tenant_consistency
    return if tenant_id.blank? || payroll_run.blank? || employee.blank?

    mismatch = tenant_id != payroll_run.tenant_id
    mismatch ||= tenant_id != employee.tenant_id
    errors.add(:tenant, "と給与計算の所属が一致しません") if mismatch
  end
end
