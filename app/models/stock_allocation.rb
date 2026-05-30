# 受注明細（OrderItem）に対する在庫引当の状態を追跡するモデル。
# reserved → consumed → released の遷移で在庫引当の消費・解放を管理する。
class StockAllocation < ApplicationRecord
  STATUSES = {
    reserved: "reserved",
    consumed: "consumed",
    released: "released"
  }.freeze

  belongs_to :tenant
  belongs_to :order_item
  belongs_to :warehouse
  belongs_to :product

  enum :status, STATUSES

  validates :allocated_quantity, :allocated_at, :status, presence: true
  validates :allocated_quantity, numericality: { greater_than: 0, only_integer: true }
  validate :tenant_consistency

  scope :active, -> { where(status: %w[reserved consumed]) }
  scope :reserved_only, -> { where(status: "reserved") }

  private

  def tenant_consistency
    return if tenant_id.blank? || order_item.blank? || warehouse.blank? || product.blank?

    if tenant_id != order_item.tenant_id || tenant_id != warehouse.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と割当先の所属が一致しません")
    end
  end
end
