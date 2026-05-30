# 支払（SupplierPayment）と仕入請求書（PurchaseBill）の消し込み明細を表すモデル。
# supplier_payment と purchase_bill の supplier_id が一致しないと弾く（クロスサプライヤー消し込み防止）。
class SupplierPaymentAllocation < ApplicationRecord
  belongs_to :tenant
  belongs_to :supplier_payment
  belongs_to :purchase_bill

  validates :allocated_amount, :allocated_at, presence: true
  validates :allocated_amount, numericality: { greater_than: 0 }
  validates :purchase_bill_id, uniqueness: { scope: :supplier_payment_id }
  validate :tenant_consistency

  before_validation :set_defaults

  private

  def set_defaults
    self.allocated_at ||= Time.current
  end

  def tenant_consistency
    return if tenant_id.blank? || supplier_payment.blank? || purchase_bill.blank?

    mismatch = tenant_id != supplier_payment.tenant_id
    mismatch ||= tenant_id != purchase_bill.tenant_id
    mismatch ||= supplier_payment.supplier_id != purchase_bill.supplier_id
    errors.add(:tenant, "と消込先の所属が一致しません") if mismatch
  end
end
