# 倉庫ごとの商品在庫を表すモデル。quantity_on_hand（実在庫）と quantity_reserved（引当済み）を分離管理する。
# 受注時に reserve! で引当し、出荷時に consume! で在庫を減らす二段階方式を採用する。
# 在庫が安全在庫を下回る閾値越えが発生した際は StockAlertJob を非同期エンキューして通知する。
class StockItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :warehouse
  belongs_to :product

  has_many :stock_counts, dependent: :restrict_with_exception

  validates :product_id, uniqueness: { scope: [ :tenant_id, :warehouse_id ] }
  validates :quantity_on_hand, :quantity_reserved, :safety_stock, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :tenant_consistency
  validate :quantity_on_hand_must_cover_reserved

  # 安全在庫以下（かつ在庫>0）の品目を DB レベルで取得する。
  scope :low_stock, -> {
    where("quantity_on_hand - quantity_reserved <= safety_stock AND quantity_on_hand - quantity_reserved > 0")
  }

  # 利用可能在庫が 0 以下の品目を DB レベルで取得する。
  scope :out_of_stock, -> {
    where("quantity_on_hand - quantity_reserved <= 0")
  }

  # 在庫一覧の表示順（倉庫名 → 商品名）。
  scope :ordered_for_admin, -> { joins(:warehouse, :product).order("warehouses.name ASC, products.name ASC") }

  # 実在庫から引当済み数を引いた利用可能在庫数を返す。
  def available_quantity
    quantity_on_hand - quantity_reserved
  end

  # 利用可能在庫が安全在庫数以下の場合に true を返す（補充アラートの判定に使う）。
  def low_stock?
    available_quantity <= safety_stock
  end

  # 利用可能在庫が 0 以下の場合に true を返す。
  def out_of_stock?
    available_quantity <= 0
  end

  # 実在庫数を delta 分増減する棚卸調整用メソッド。在庫がマイナスまたは引当数未満になる場合は例外を上げる。
  def adjust_on_hand!(delta)
    adjustment = delta.to_i
    raise ArgumentError, "在庫増減数は0以外で入力してください" if adjustment.zero?

    next_quantity = quantity_on_hand + adjustment
    raise ArgumentError, "在庫数をマイナスにはできません" if next_quantity.negative?
    raise ArgumentError, "在庫数を引当数未満にはできません" if next_quantity < quantity_reserved

    was_low = low_stock?
    update!(quantity_on_hand: next_quantity)
    enqueue_alert_if_threshold_crossed!(was_low)
  end

  # 受注時に利用可能在庫を引当済みに移す。不足時は例外を上げる。
  def reserve!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "数量は1以上で入力してください" if qty <= 0
    raise ArgumentError, "利用可能在庫が不足しています" if available_quantity < qty

    was_low = low_stock?
    update!(quantity_reserved: quantity_reserved + qty)
    enqueue_alert_if_threshold_crossed!(was_low)
  end

  # 出荷時に引当済み在庫を実在庫とともに減らす。出荷消費は引当を経由するため二重チェックする。
  # on_hand と reserved を同量減らすため available_quantity は変化しない。
  # アラート検出は reserve! と adjust_on_hand! 側で行う。
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

  # 安全在庫を超えている状態から下回った瞬間のみジョブをエンキューする。
  # 既に閾値を下回っている場合は追加通知しない（スパム防止）。
  def enqueue_alert_if_threshold_crossed!(was_low_before)
    return if was_low_before      # 元から低在庫なら通知不要
    return unless low_stock?      # 更新後も問題なければ通知不要

    StockAlertJob.perform_later(id)
  end

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
