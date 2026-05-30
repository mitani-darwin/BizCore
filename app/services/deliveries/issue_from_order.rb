module Deliveries
  # 受注から納品書を発行し、在庫の引当消費と注文ステータスを更新するサービス。
  # 引当済み（reserved）在庫がない場合は NothingToDeliverError を上げる。
  class IssueFromOrder
    # 引当済み在庫がない場合に上げる例外。
    class NothingToDeliverError < StandardError; end

    def self.call(order:, delivery_date:, issued_at: Time.current)
      new(order:, delivery_date:, issued_at:).call
    end

    def initialize(order:, delivery_date:, issued_at:)
      @order = order
      @delivery_date = delivery_date
      @issued_at = issued_at
    end

    def call
      reserved_items = order.order_items.includes(stock_allocations: [ :warehouse, :product ]).select do |item|
        item.stock_allocations.reserved_only.exists?
      end
      raise NothingToDeliverError, "reserved stock was not found" if reserved_items.empty?

      delivery = nil
      order.transaction do
        delivery = order.deliveries.create!(
          tenant: order.tenant,
          customer: order.customer,
          delivery_date: delivery_date,
          issued_at: issued_at,
          delivery_address: order.delivery_address,
          remarks: order.remarks
        )

        reserved_items.each do |item|
          issue_item!(delivery, item)
        end

        update_order_status!
      end

      delivery
    end

    private

    attr_reader :order, :delivery_date, :issued_at

    def issue_item!(delivery, item)
      allocations = item.stock_allocations.reserved_only.includes(:warehouse, :product)
      delivered_quantity = allocations.sum(&:allocated_quantity)
      return if delivered_quantity <= 0

      delivery.delivery_items.create!(
        tenant: order.tenant,
        order_item: item,
        product: item.product,
        delivered_quantity: delivered_quantity,
        unit_price: item.unit_price
      )

      allocations.each do |allocation|
        stock_item = StockItem.lock.find_by!(
          tenant: order.tenant,
          warehouse: allocation.warehouse,
          product: allocation.product
        )
        stock_item.consume!(allocation.allocated_quantity)
        StockMovement.create!(
          tenant: order.tenant,
          warehouse: allocation.warehouse,
          product: allocation.product,
          movement_type: "outbound",
          quantity: allocation.allocated_quantity,
          occurred_on: delivery_date,
          reference: delivery,
          note: "#{delivery.delivery_number} の出荷"
        )
        allocation.update!(status: "consumed", released_at: issued_at)
      end

      item.reload
      item.update!(status: item.remaining_to_deliver.zero? ? "delivered" : "allocated")
    end

    def update_order_status!
      return unless order.order_items.all? { |item| item.remaining_to_deliver.zero? }

      order.update!(status: "delivered")
    end
  end
end
