# 月次給与計算のバッチ実行単位を表すモデル。
# 1テナント・1月につき 1 件のみ作成でき、確定（confirmed）後は変更不可。
class PayrollRun < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    generated: "generated",
    confirmed: "confirmed"
  }.freeze

  belongs_to :tenant
  belongs_to :generated_by, class_name: "User", optional: true
  belongs_to :confirmed_by, class_name: "User", optional: true

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

  # 給与計算を確定し、以降の変更を防ぐ。二重確定は例外を上げる。
  def confirm!(confirmed_by:)
    raise "確定済みの給与計算は再確定できません" if confirmed?

    update!(status: "confirmed", confirmed_at: Time.current, confirmed_by: confirmed_by)
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
