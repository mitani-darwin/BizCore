class StockItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :warehouse
  belongs_to :product

  validates :product_id, uniqueness: { scope: [:tenant_id, :warehouse_id] }
  validates :quantity_on_hand, :quantity_reserved, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency
  validate :quantity_on_hand_must_cover_reserved

  def available_quantity
    quantity_on_hand - quantity_reserved
  end

  def reserve!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "quantity must be positive" if qty <= 0
    raise ArgumentError, "insufficient stock" if available_quantity < qty

    update!(quantity_reserved: quantity_reserved + qty)
  end

  def consume!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "quantity must be positive" if qty <= 0
    raise ArgumentError, "reserved stock is insufficient" if quantity_reserved < qty
    raise ArgumentError, "on hand stock is insufficient" if quantity_on_hand < qty

    update!(
      quantity_on_hand: quantity_on_hand - qty,
      quantity_reserved: quantity_reserved - qty
    )
  end

  private

  def tenant_consistency
    return if tenant_id.blank? || warehouse.blank? || product.blank?

    if tenant_id != warehouse.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と倉庫/商品の所属が一致しません")
    end
  end

  def quantity_on_hand_must_cover_reserved
    return if quantity_on_hand.blank? || quantity_reserved.blank?
    return if quantity_on_hand >= quantity_reserved

    errors.add(:quantity_on_hand, "は引当済在庫以上である必要があります")
  end
end
