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
    raise ArgumentError, "在庫増減数は0以外で入力してください" if adjustment.zero?

    next_quantity = quantity_on_hand + adjustment
    raise ArgumentError, "在庫数をマイナスにはできません" if next_quantity.negative?
    raise ArgumentError, "在庫数を引当数未満にはできません" if next_quantity < quantity_reserved

    update!(quantity_on_hand: next_quantity)
  end

  def reserve!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "数量は1以上で入力してください" if qty <= 0
    raise ArgumentError, "利用可能在庫が不足しています" if available_quantity < qty

    update!(quantity_reserved: quantity_reserved + qty)
  end

  def consume!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "数量は1以上で入力してください" if qty <= 0
    raise ArgumentError, "引当済在庫が不足しています" if quantity_reserved < qty
    raise ArgumentError, "在庫数が不足しています" if quantity_on_hand < qty

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
