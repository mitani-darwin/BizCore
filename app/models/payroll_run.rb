class PayrollRun < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    generated: "generated",
    confirmed: "confirmed"
  }.freeze

  belongs_to :tenant
  belongs_to :generated_by, class_name: "User", optional: true

  has_many :payroll_entries, dependent: :destroy

  enum :status, STATUSES

  generates_document_number :run_number, prefix: "PRL"

  scope :ordered_for_admin, -> { order(payroll_month: :desc, id: :desc) }

  validates :run_number, :payroll_month, :status, presence: true
  validates :payroll_month, uniqueness: { scope: :tenant_id }
  validates :total_gross_pay, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency

  before_validation :set_defaults

  def title
    run_number
  end

  private

  def set_defaults
    self.status ||= "generated"
    self.payroll_month = payroll_month&.beginning_of_month
    self.generated_at ||= Time.current
  end

  def tenant_consistency
    return if tenant_id.blank?
    return unless generated_by.present?

    errors.add(:tenant, "と作成者の所属が一致しません") if tenant_id != generated_by.tenant_id
  end
end
