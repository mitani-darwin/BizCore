module Invoicing
  class ReissueInvoice
    def self.call(invoice:, invoice_date: Date.current, default_due_date: nil)
      new(invoice: invoice, invoice_date: invoice_date, default_due_date: default_due_date).call
    end

    def initialize(invoice:, invoice_date:, default_due_date:)
      @invoice = invoice
      @invoice_date = invoice_date
      @default_due_date = default_due_date
    end

    def call
      raise ArgumentError, "取消済みの請求書のみ再発行できます" unless invoice.cancelled?
      raise ArgumentError, "すでに再発行済みの請求書です" if invoice.reissues.where.not(status: "cancelled").exists?
      raise ArgumentError, "同じ納品明細の請求がすでに有効です" if active_source_invoice_exists?

      reissued_invoice = nil

      invoice.transaction do
        reissued_invoice = invoice.tenant.invoices.create!(
          billing_batch: invoice.billing_batch,
          reissued_from: invoice,
          customer: invoice.customer,
          closing_date: invoice.closing_date,
          billing_period_from: invoice.billing_period_from,
          billing_period_to: invoice.billing_period_to,
          invoice_date: invoice_date,
          due_date: invoice.customer.due_date_for(closing_date: invoice.closing_date, default_due_date: default_due_date || invoice.due_date),
          closing_day_snapshot: invoice.closing_day_snapshot,
          payment_due_rule_snapshot: invoice.payment_due_rule_snapshot,
          invoice_delivery_method_snapshot: invoice.invoice_delivery_method_snapshot,
          remarks: [ invoice.remarks.presence, "再発行元: #{invoice.invoice_number}" ].compact.join("\n")
        )

        invoice.invoice_items.find_each do |item|
          reissued_invoice.invoice_items.create!(
            tenant: invoice.tenant,
            source: item.source,
            description: item.description,
            quantity: item.quantity,
            unit_price: item.unit_price,
            tax_category: item.tax_category
          )
        end

        reissued_invoice.recalculate_totals!
        refresh_sources_as_billed!(reissued_invoice)
        invoice.billing_batch&.reload&.refresh_statistics!
      end

      reissued_invoice
    end

    private

    attr_reader :invoice, :invoice_date, :default_due_date

    def active_source_invoice_exists?
      invoice.invoice_items.any? do |item|
        item.source.present? && item.source.invoice_items.active_for_source.exists?
      end
    end

    def refresh_sources_as_billed!(reissued_invoice)
      delivery_items = reissued_invoice.invoice_items.includes(:source).map(&:source).compact.uniq

      delivery_items.each do |delivery_item|
        delivery_item.delivery.update!(status: "billed")
        delivery_item.order_item.update!(status: "billed")

        order = delivery_item.order_item.order
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
  end
end
