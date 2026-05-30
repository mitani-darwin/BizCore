module Purchases
  # 仕入返品・値引きを登録し、返品の場合は在庫の出庫調整も同時に行うサービス。
  class RegisterAdjustment
    def self.call(purchase_receipt:, adjustment_type:, adjustment_date:, processed_by_name:, reason:, purchase_receipt_item_id: nil, quantity: nil, amount: nil)
      new(
        purchase_receipt: purchase_receipt,
        adjustment_type: adjustment_type,
        adjustment_date: adjustment_date,
        processed_by_name: processed_by_name,
        reason: reason,
        purchase_receipt_item_id: purchase_receipt_item_id,
        quantity: quantity,
        amount: amount
      ).call
    end

    def initialize(purchase_receipt:, adjustment_type:, adjustment_date:, processed_by_name:, reason:, purchase_receipt_item_id:, quantity:, amount:)
      @purchase_receipt = purchase_receipt
      @adjustment_type = adjustment_type.to_s
      @adjustment_date = adjustment_date
      @processed_by_name = processed_by_name
      @reason = reason
      @purchase_receipt_item_id = purchase_receipt_item_id
      @quantity = quantity
      @amount = amount
    end

    def call
      raise ArgumentError, "調整区分が正しくありません" unless PurchaseAdjustment.adjustment_types.value?(adjustment_type)

      adjustment_type == "purchase_return" ? create_return_adjustment : create_discount_adjustment
    end

    private

    attr_reader :purchase_receipt, :adjustment_type, :adjustment_date, :processed_by_name, :reason, :purchase_receipt_item_id, :quantity, :amount

    def create_return_adjustment
      receipt_item = purchase_receipt.purchase_receipt_items.includes(:product).find_by(id: purchase_receipt_item_id)
      raise ArgumentError, "返品対象の入荷明細を選択してください" if receipt_item.nil?

      return_quantity = quantity.to_i
      raise ArgumentError, "返品数量は1以上で入力してください" if return_quantity <= 0
      raise ArgumentError, "返品数量が返品可能数を超えています" if return_quantity > receipt_item.returnable_quantity

      adjustment = nil
      purchase_receipt.transaction do
        adjustment = purchase_receipt.tenant.purchase_adjustments.create!(
          supplier: purchase_receipt.supplier,
          warehouse: purchase_receipt.warehouse,
          purchase_order: purchase_receipt.purchase_order,
          purchase_receipt: purchase_receipt,
          purchase_receipt_item: receipt_item,
          product: receipt_item.product,
          adjustment_type: "purchase_return",
          adjustment_date: adjustment_date,
          processed_by_name: processed_by_name,
          reason: reason,
          quantity: return_quantity,
          unit_cost: receipt_item.unit_cost,
          amount: receipt_item.unit_cost.to_d * return_quantity
        )

        stock_item = purchase_receipt.tenant.stock_items.find_by(
          warehouse: purchase_receipt.warehouse,
          product: receipt_item.product
        )
        raise ArgumentError, "返品対象の在庫が見つかりません" if stock_item.nil?

        Inventory::RecordMovement.call(
          stock_item: stock_item,
          movement_type: "outbound",
          quantity: return_quantity,
          occurred_on: adjustment_date,
          note: "返品 #{adjustment.adjustment_number} / 入荷 #{purchase_receipt.purchase_receipt_number}",
          reference: adjustment
        )
      end

      adjustment
    end

    def create_discount_adjustment
      discount_amount = BigDecimal(amount.presence || "0")
      raise ArgumentError, "値引金額は0より大きく入力してください" if discount_amount <= 0

      purchase_receipt.tenant.purchase_adjustments.create!(
        supplier: purchase_receipt.supplier,
        warehouse: purchase_receipt.warehouse,
        purchase_order: purchase_receipt.purchase_order,
        purchase_receipt: purchase_receipt,
        adjustment_type: "discount",
        adjustment_date: adjustment_date,
        processed_by_name: processed_by_name,
        reason: reason,
        quantity: 0,
        unit_cost: 0,
        amount: discount_amount
      )
    end
  end
end
