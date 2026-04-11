module Inventory
  class RecordMovement
    ALLOWED_TYPES = %w[inbound adjustment adjustment_increase adjustment_decrease].freeze

    def self.call(stock_item:, movement_type:, quantity:, occurred_on:, note:, reference: nil)
      new(
        stock_item: stock_item,
        movement_type: movement_type,
        quantity: quantity,
        occurred_on: occurred_on,
        note: note,
        reference: reference
      ).call
    end

    def initialize(stock_item:, movement_type:, quantity:, occurred_on:, note:, reference:)
      @stock_item = stock_item
      @movement_type = movement_type.to_s
      @quantity = quantity.to_i
      @occurred_on = occurred_on
      @note = note
      @reference = reference
    end

    def call
      raise ArgumentError, "unsupported movement type" unless ALLOWED_TYPES.include?(movement_type)
      raise ArgumentError, "quantity must be positive" if quantity <= 0

      movement = nil
      stock_item.transaction do
        stock_item.adjust_on_hand!(signed_delta)
        movement = StockMovement.create!(
          tenant: stock_item.tenant,
          warehouse: stock_item.warehouse,
          product: stock_item.product,
          movement_type: movement_type,
          quantity: quantity,
          occurred_on: occurred_on,
          reference: reference,
          note: note
        )
      end

      movement
    end

    private

    attr_reader :stock_item, :movement_type, :quantity, :occurred_on, :note, :reference

    def signed_delta
      case movement_type
      when "inbound", "adjustment", "adjustment_increase"
        quantity
      when "adjustment_decrease"
        -quantity
      else
        raise ArgumentError, "unsupported movement type"
      end
    end
  end
end
