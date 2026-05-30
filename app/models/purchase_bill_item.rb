# 仕入請求書（PurchaseBill）の明細行を表すモデル。InvoiceItem の仕入側に対応する。
# source は PurchaseReceiptItem または PurchaseAdjustment で、税区分はその連鎖から遡及して決定する。
class PurchaseBillItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :purchase_bill
  belongs_to :source, polymorphic: true, optional: true

  scope :active_for_source, lambda {
    joins(:purchase_bill).where.not(purchase_bills: { status: "cancelled" })
  }

  validates :description, :quantity, :unit_price, :amount, :tax_category, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :amount, numericality: true
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :calculate_amount

  def tax_amount
    TaxSupport.tax_amount_for(amount, tax_category)
  end

  private

  def set_defaults
    self.tax_category ||= source_tax_category
  end

  def source_tax_category
    case source
    when PurchaseReceiptItem
      source.purchase_order_item&.tax_category_snapshot || source.product&.tax_category || "taxable_10"
    when PurchaseAdjustment
      source.purchase_receipt_item&.purchase_order_item&.tax_category_snapshot ||
        source.product&.tax_category ||
        source.purchase_receipt.purchase_receipt_items.first&.purchase_order_item&.tax_category_snapshot ||
        "taxable_10"
    else
      "taxable_10"
    end
  end

  def calculate_amount
    return if quantity.blank? || unit_price.blank?

    self.amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
  end

  def tenant_consistency
    return if tenant_id.blank? || purchase_bill.blank?

    mismatch = tenant_id != purchase_bill.tenant_id
    mismatch ||= source.respond_to?(:tenant_id) && tenant_id != source.tenant_id
    errors.add(:tenant, "と請求元の所属が一致しません") if mismatch
  end
end
