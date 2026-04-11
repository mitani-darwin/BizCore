module Inventory
  class ReserveOrder
    class InsufficientStockError < StandardError; end

    def self.call(order:, warehouse:, allocated_at: Time.current)
      new(order:, warehouse:, allocated_at:).call
    end

    def initialize(order:, warehouse:, allocated_at:)
      @order = order
      @warehouse = warehouse
      @allocated_at = allocated_at
    end

    def call
      raise ArgumentError, "order must be accepted before reservation" unless order.accepted? || order.allocated?
      raise ArgumentError, "warehouse does not belong to the same tenant" unless warehouse.tenant_id == order.tenant_id

      order.transaction do
        order.order_items.includes(:product, :stock_allocations).find_each do |item|
          reserve_item!(item)
        end

        order.update!(status: "allocated") if order.order_items.all? { |item| item.remaining_to_allocate.zero? }
      end

      order
    end

    private

    attr_reader :order, :warehouse, :allocated_at

    def reserve_item!(item)
      remaining = item.remaining_to_allocate
      return if remaining <= 0

      stock_item = StockItem.lock.find_or_create_by!(
        tenant: order.tenant,
        warehouse: warehouse,
        product: item.product
      ) do |record|
        record.quantity_on_hand = 0
        record.quantity_reserved = 0
      end

      if stock_item.available_quantity < remaining
        raise InsufficientStockError, "#{item.product_name_snapshot} の在庫が不足しています"
      end

      stock_item.reserve!(remaining)
      item.stock_allocations.create!(
        tenant: order.tenant,
        warehouse: warehouse,
        product: item.product,
        allocated_quantity: remaining,
        status: "reserved",
        allocated_at: allocated_at
      )
      item.update!(status: "allocated")
    end
  end
end
