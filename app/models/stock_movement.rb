class StockMovement < ApplicationRecord
  belongs_to :tenant
  belongs_to :warehouse
  belongs_to :product
  belongs_to :reference, polymorphic: true, optional: true

  MOVEMENT_TYPES = {
    inbound: "inbound",
    outbound: "outbound",
    adjustment: "adjustment"
  }.freeze

  enum :movement_type, MOVEMENT_TYPES

  validates :movement_type, :quantity, :occurred_on, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validate :tenant_consistency

  private

  def tenant_consistency
    return if tenant_id.blank? || warehouse.blank? || product.blank?

    if tenant_id != warehouse.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と倉庫/商品の所属が一致しません")
    end
  end
end
