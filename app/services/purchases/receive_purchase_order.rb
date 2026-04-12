module Purchases
  class ReceivePurchaseOrder
    def self.call(purchase_order:, received_on:, received_by_name:, remarks:, quantities:)
      new(
        purchase_order: purchase_order,
        received_on: received_on,
        received_by_name: received_by_name,
        remarks: remarks,
        quantities: quantities
      ).call
    end

    def initialize(purchase_order:, received_on:, received_by_name:, remarks:, quantities:)
      @purchase_order = purchase_order
      @received_on = received_on
      @received_by_name = received_by_name
      @remarks = remarks
      @quantities = quantities
    end

    def call
      raise ArgumentError, "purchase order is not receivable" unless purchase_order.receivable?

      receipt_quantities = normalize_quantities
      raise ArgumentError, "入荷数量を入力してください" if receipt_quantities.empty?

      receipt = nil
      purchase_order.transaction do
        receipt = purchase_order.tenant.purchase_receipts.create!(
          purchase_order: purchase_order,
          supplier: purchase_order.supplier,
          warehouse: purchase_order.warehouse,
          received_on: received_on,
          received_by_name: received_by_name,
          remarks: remarks
        )

        receipt_quantities.each do |item, quantity|
          receipt.purchase_receipt_items.create!(
            tenant: purchase_order.tenant,
            purchase_order_item: item,
            product: item.product,
            received_quantity: quantity,
            unit_cost: item.unit_cost
          )

          stock_item = find_or_prepare_stock_item(item.product)
          Inventory::RecordMovement.call(
            stock_item: stock_item,
            movement_type: "inbound",
            quantity: quantity,
            occurred_on: received_on,
            note: "入荷 #{receipt.purchase_receipt_number} / 発注 #{purchase_order.purchase_order_number}",
            reference: receipt
          )

          item.register_receipt!(quantity)
        end

        purchase_order.reload.refresh_receipt_status!
      end

      receipt
    end

    private

    attr_reader :purchase_order, :received_on, :received_by_name, :remarks, :quantities

    def normalize_quantities
      items = purchase_order.purchase_order_items.index_by(&:id)
      quantities.to_h.each_with_object({}) do |(item_id, raw_quantity), result|
        quantity = raw_quantity.to_i
        next if quantity <= 0

        item = items[item_id.to_i]
        raise ArgumentError, "対象の発注明細が見つかりません" if item.nil?
        raise ArgumentError, "入荷数量が残数量を超えています" if quantity > item.remaining_quantity

        result[item] = quantity
      end
    end

    def find_or_prepare_stock_item(product)
      stock_item = purchase_order.tenant.stock_items.find_or_initialize_by(
        warehouse: purchase_order.warehouse,
        product: product
      )
      return stock_item if stock_item.persisted?

      stock_item.quantity_on_hand = 0
      stock_item.quantity_reserved = 0
      stock_item.safety_stock = 0
      stock_item.save!
      stock_item
    end
  end
end
