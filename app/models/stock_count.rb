# 棚卸実績を表すモデル。実地棚卸で計測した数量と帳簿在庫の差分（adjustment_quantity）を記録する。
class StockCount < ApplicationRecord
  belongs_to :tenant
  belongs_to :stock_item
  belongs_to :warehouse
  belongs_to :product

  validates :quantity_before, :counted_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :adjustment_quantity, numericality: { only_integer: true }
  validates :counted_at, presence: true
  validate :tenant_consistency

  scope :recent, -> { order(counted_at: :desc, id: :desc) }

  private

  def tenant_consistency
    return if tenant_id.blank? || stock_item.blank? || warehouse.blank? || product.blank?

    mismatch = tenant_id != stock_item.tenant_id
    mismatch ||= tenant_id != warehouse.tenant_id
    mismatch ||= tenant_id != product.tenant_id
    mismatch ||= stock_item.warehouse_id != warehouse_id
    mismatch ||= stock_item.product_id != product_id
    return unless mismatch

    errors.add(:tenant, "と棚卸対象の所属が一致しません")
  end
end
