module Invoicing
  # 個別の請求書を取消するサービス。消し込み済みの入金がある場合は取消不可。
  class CancelInvoice
    def self.call(invoice:, cancelled_by: nil, cancelled_at: Time.current)
      new(invoice: invoice, cancelled_by: cancelled_by, cancelled_at: cancelled_at).call
    end

    def initialize(invoice:, cancelled_by:, cancelled_at:)
      @invoice = invoice
      @cancelled_by = cancelled_by
      @cancelled_at = cancelled_at
    end

    def call
      raise ArgumentError, "すでに取消済みの請求書です" if invoice.cancelled?
      raise ArgumentError, "入金済みの請求書は取消できません" if invoice.payment_allocations.exists?

      invoice.transaction do
        invoice.update!(status: "cancelled", cancelled_at: cancelled_at)
        refresh_sources!
        invoice.billing_batch&.reload&.refresh_statistics!
      end

      invoice
    end

    private

    attr_reader :invoice, :cancelled_by, :cancelled_at

    def refresh_sources!
      sources = invoice.invoice_items.includes(:source).map(&:source).compact.uniq

      sources.each do |delivery_item|
        delivery = delivery_item.delivery
        order_item = delivery_item.order_item

        delivery.update!(status: active_invoice_exists_for_delivery?(delivery) ? "billed" : "issued")
        order_item.update!(status: active_invoice_exists_for_order_item?(order_item) ? "billed" : "delivered")

        order = order_item.order
        order_status =
          if order.order_items.all? { |item| item.status == "billed" }
            "billed"
          elsif order.order_items.all? { |item| %w[delivered billed].include?(item.status) }
            "delivered"
          else
            order.status
          end
        order.update!(status: order_status) if order.status != order_status
      end
    end

    def active_invoice_exists_for_delivery?(delivery)
      delivery.delivery_items.any? { |item| item.invoice_items.active_for_source.exists? }
    end

    def active_invoice_exists_for_order_item?(order_item)
      order_item.delivery_items.any? { |item| item.invoice_items.active_for_source.exists? }
    end
  end
end
