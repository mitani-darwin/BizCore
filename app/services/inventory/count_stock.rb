module Inventory
  class CountStock
    def self.call(stock_item:, counted_quantity:, counted_at:, note: nil)
      new(
        stock_item: stock_item,
        counted_quantity: counted_quantity,
        counted_at: counted_at,
        note: note
      ).call
    end

    def initialize(stock_item:, counted_quantity:, counted_at:, note:)
      @stock_item = stock_item
      @counted_quantity = counted_quantity.to_i
      @counted_at = counted_at
      @note = note
    end

    def call
      raise ArgumentError, "counted quantity must be non-negative" if counted_quantity.negative?

      stock_count = nil
      stock_item.transaction do
        quantity_before = stock_item.quantity_on_hand
        adjustment_quantity = counted_quantity - quantity_before

        stock_count = StockCount.create!(
          tenant: stock_item.tenant,
          stock_item: stock_item,
          warehouse: stock_item.warehouse,
          product: stock_item.product,
          quantity_before: quantity_before,
          counted_quantity: counted_quantity,
          adjustment_quantity: adjustment_quantity,
          counted_at: counted_at,
          note: note
        )

        apply_adjustment!(stock_count) unless adjustment_quantity.zero?
      end

      stock_count
    end

    private

    attr_reader :stock_item, :counted_quantity, :counted_at, :note

    def apply_adjustment!(stock_count)
      movement_type = stock_count.adjustment_quantity.positive? ? "adjustment_increase" : "adjustment_decrease"
      Inventory::RecordMovement.call(
        stock_item: stock_item,
        movement_type: movement_type,
        quantity: stock_count.adjustment_quantity.abs,
        occurred_on: stock_count.counted_at.to_date,
        note: stock_count.note.presence || "棚卸差異の反映",
        reference: stock_count
      )
    end
  end
end
