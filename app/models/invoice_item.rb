# 請求書（Invoice）の明細行を表すモデル。
# source（多態関連）は納品明細（DeliveryItem）等を参照し、再発行時の整合性チェックにも使う。
# active_for_source スコープはキャンセル済み請求書の明細を除外するために使用する。
class InvoiceItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :invoice
  belongs_to :source, polymorphic: true, optional: true

  scope :active_for_source, lambda {
    joins(:invoice).where.not(invoices: { status: "cancelled" })
  }

  validates :description, :quantity, :unit_price, :amount, :tax_category, presence: true
  validate :invoice_must_not_be_locked, on: [ :update, :destroy ]
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :calculate_amount

  def tax_amount
    TaxSupport.tax_amount_for(amount, tax_category)
  end

  private

  def set_defaults
    self.tax_category ||= source.try(:tax_category) || "taxable_10"
  end

  def calculate_amount
    return if quantity.blank? || unit_price.blank?

    self.amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
  end

  # 電子帳簿保存法: 発行済み・一部入金済み・入金済みの請求書明細は変更・削除不可
  def invoice_must_not_be_locked
    return if invoice.blank?
    return if invoice.cancelled?

    errors.add(:base, "発行済みの請求書明細は変更できません（電子帳簿保存法）")
  end

  def tenant_consistency
    return if tenant_id.blank? || invoice.blank?

    mismatch = tenant_id != invoice.tenant_id
    mismatch ||= source.respond_to?(:tenant_id) && tenant_id != source.tenant_id

    if mismatch
      errors.add(:tenant, "と請求元の所属が一致しません")
    end
  end
end
