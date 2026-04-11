class StockItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :warehouse
  belongs_to :product

  has_many :stock_counts, dependent: :restrict_with_exception

  validates :product_id, uniqueness: { scope: [:tenant_id, :warehouse_id] }
  validates :quantity_on_hand, :quantity_reserved, :safety_stock, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency
  validate :quantity_on_hand_must_cover_reserved

  def available_quantity
    quantity_on_hand - quantity_reserved
  end

  def low_stock?
    available_quantity <= safety_stock
  end

  def adjust_on_hand!(delta)
    adjustment = delta.to_i
    raise ArgumentError, "adjustment must not be zero" if adjustment.zero?

    next_quantity = quantity_on_hand + adjustment
    raise ArgumentError, "quantity must not be negative" if next_quantity.negative?
    raise ArgumentError, "quantity must not be lower than reserved stock" if next_quantity < quantity_reserved

    update!(quantity_on_hand: next_quantity)
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
