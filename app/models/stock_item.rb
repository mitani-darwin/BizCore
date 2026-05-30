# 倉庫ごとの商品在庫を表すモデル。quantity_on_hand（実在庫）と quantity_reserved（引当済み）を分離管理する。
# 受注時に reserve! で引当し、出荷時に consume! で在庫を減らす二段階方式を採用する。
class StockItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :warehouse
  belongs_to :product

  has_many :stock_counts, dependent: :restrict_with_exception

  validates :product_id, uniqueness: { scope: [ :tenant_id, :warehouse_id ] }
  validates :quantity_on_hand, :quantity_reserved, :safety_stock, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency
  validate :quantity_on_hand_must_cover_reserved

  # 実在庫から引当済み数を引いた利用可能在庫数を返す。
  def available_quantity
    quantity_on_hand - quantity_reserved
  end

  # 利用可能在庫が安全在庫数以下の場合に true を返す（補充アラートの判定に使う）。
  def low_stock?
    available_quantity <= safety_stock
  end

  # 実在庫数を delta 分増減する棚卸調整用メソッド。在庫がマイナスまたは引当数未満になる場合は例外を上げる。
  def adjust_on_hand!(delta)
    adjustment = delta.to_i
    raise ArgumentError, "在庫増減数は0以外で入力してください" if adjustment.zero?

    next_quantity = quantity_on_hand + adjustment
    raise ArgumentError, "在庫数をマイナスにはできません" if next_quantity.negative?
    raise ArgumentError, "在庫数を引当数未満にはできません" if next_quantity < quantity_reserved

    update!(quantity_on_hand: next_quantity)
  end

  # 受注時に利用可能在庫を引当済みに移す。不足時は例外を上げる。
  def reserve!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "数量は1以上で入力してください" if qty <= 0
    raise ArgumentError, "利用可能在庫が不足しています" if available_quantity < qty

    update!(quantity_reserved: quantity_reserved + qty)
  end

  # 出荷時に引当済み在庫を実在庫とともに減らす。出荷消費は引当を経由するため二重チェックする。
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
