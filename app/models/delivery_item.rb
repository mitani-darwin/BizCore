# 納品書（Delivery）の明細行を表すモデル。
# 受注明細（OrderItem）から商品情報をスナップショットとして引き継ぐ。
# invoice_items の source として参照されるため、請求生成後は restrict_with_exception で削除を防ぐ。
class DeliveryItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :delivery
  belongs_to :order_item
  belongs_to :product

  has_many :invoice_items, as: :source, dependent: :restrict_with_exception

  validates :delivered_quantity, :unit_price, :amount, presence: true
  validates :delivered_quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :snapshot_sources
  before_validation :calculate_amount

  def tax_category
    order_item.tax_category_snapshot
  end

  private

  def snapshot_sources
    self.product_code_snapshot ||= order_item&.product_code_snapshot || product&.code
    self.product_name_snapshot ||= order_item&.product_name_snapshot || product&.name
    self.unit_name_snapshot ||= order_item&.unit_name_snapshot || product&.unit_name
    self.unit_price ||= order_item&.unit_price || product&.standard_price || 0
  end

  def calculate_amount
    return if delivered_quantity.blank? || unit_price.blank?

    self.amount = BigDecimal(delivered_quantity.to_s) * BigDecimal(unit_price.to_s)
  end

  def tenant_consistency
    return if tenant_id.blank? || delivery.blank? || order_item.blank? || product.blank?

    if tenant_id != delivery.tenant_id || tenant_id != order_item.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と納品先の所属が一致しません")
    end
  end
end
