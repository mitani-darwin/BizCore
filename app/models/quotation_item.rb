# 見積書（Quotation）の明細行を表すモデル。
# 商品マスタの情報をスナップショットとして保存し、後からの商品変更に影響されない。
# 税額は TaxSupport を使って tax_category_snapshot ベースで算出する。
class QuotationItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :quotation
  belongs_to :product

  validates :line_no, :quantity, :unit_price, :amount, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :line_no, uniqueness: { scope: :quotation_id }
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :inherit_tenant
  before_validation :snapshot_product
  before_validation :calculate_amount

  def tax_amount
    TaxSupport.tax_amount_for(amount, tax_category_snapshot)
  end

  private

  def set_defaults
    self.line_no ||= next_line_no
    self.unit_price ||= product&.standard_price || 0
  end

  def inherit_tenant
    self.tenant ||= quotation&.tenant
  end

  def snapshot_product
    return unless product

    self.product_code_snapshot ||= product.code
    self.product_name_snapshot ||= product.name
    self.unit_name_snapshot ||= product.unit_name
    self.tax_category_snapshot ||= product.tax_category
  end

  def calculate_amount
    return if quantity.blank? || unit_price.blank?

    self.amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
  end

  def next_line_no
    return 1 unless quotation

    existing = quotation.quotation_items.reject { |item| item.equal?(self) }
    existing.map(&:line_no).compact.max.to_i + 1
  end

  def tenant_consistency
    return if tenant_id.blank? || quotation.blank? || product.blank?

    if tenant_id != quotation.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と見積/商品の所属が一致しません")
    end
  end
end
