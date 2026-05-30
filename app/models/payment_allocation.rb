# 入金（Payment）と請求書（Invoice）の消し込み明細を表すモデル。
# 1 件の入金を複数の請求書に分割消し込みでき、消し込み後に Invoice#recalculate_totals! を呼ぶ。
class PaymentAllocation < ApplicationRecord
  belongs_to :tenant
  belongs_to :payment
  belongs_to :invoice

  validates :allocated_amount, :allocated_at, presence: true
  validates :allocated_amount, numericality: { greater_than: 0 }
  validates :invoice_id, uniqueness: { scope: :payment_id }
  validate :tenant_consistency

  before_validation :set_defaults

  private

  def set_defaults
    self.allocated_at ||= Time.current
  end

  def tenant_consistency
    return if tenant_id.blank? || payment.blank? || invoice.blank?

    if tenant_id != payment.tenant_id || tenant_id != invoice.tenant_id
      errors.add(:tenant, "と消込先の所属が一致しません")
    end
  end
end
