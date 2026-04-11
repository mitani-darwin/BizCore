module Invoicing
  class IssueMonthlyInvoices
    def self.call(tenant:, closing_date:, invoice_date:, due_date:, billing_period_from: closing_date.beginning_of_month, billing_period_to: closing_date.end_of_month)
      new(
        tenant: tenant,
        closing_date: closing_date,
        billing_period_from: billing_period_from,
        billing_period_to: billing_period_to,
        invoice_date: invoice_date,
        due_date: due_date
      ).call
    end

    def initialize(tenant:, closing_date:, billing_period_from:, billing_period_to:, invoice_date:, due_date:)
      @tenant = tenant
      @closing_date = closing_date
      @billing_period_from = billing_period_from
      @billing_period_to = billing_period_to
      @invoice_date = invoice_date
      @due_date = due_date
    end

    def call
      billable_items.group_by { |item| item.delivery.customer }.each_with_object([]) do |(customer, items), invoices|
        next if items.empty?

        invoice = tenant.invoices.create!(
          customer: customer,
          closing_date: closing_date,
          billing_period_from: billing_period_from,
          billing_period_to: billing_period_to,
          invoice_date: invoice_date,
          due_date: due_date
        )

        items.each do |item|
          invoice.invoice_items.create!(
            tenant: tenant,
            source: item,
            description: "#{item.product_name_snapshot} (#{item.delivery.delivery_number})",
            quantity: item.delivered_quantity,
            unit_price: item.unit_price,
            tax_category: item.tax_category
          )
        end

        invoice.recalculate_totals!
        mark_sources_as_billed!(items)
        invoices << invoice
      end
    end

    private

    attr_reader :tenant, :closing_date, :billing_period_from, :billing_period_to, :invoice_date, :due_date

    def billable_items
      DeliveryItem
        .includes(:order_item, delivery: :customer)
        .joins(:delivery)
        .left_outer_joins(:invoice_items)
        .where(
          tenant_id: tenant.id,
          deliveries: {
            delivery_date: billing_period_from..billing_period_to,
            status: %w[issued billed]
          }
        )
        .where(invoice_items: { id: nil })
    end

    def mark_sources_as_billed!(items)
      items.each do |item|
        delivery = item.delivery
        order_item = item.order_item

        if delivery.delivery_items.all? { |delivery_item| delivery_item.invoice_items.exists? }
          delivery.update!(status: "billed")
        end

        if order_item.delivery_items.all? { |delivery_item| delivery_item.invoice_items.exists? }
          order_item.update!(status: "billed")
        end

        order = order_item.order
        if order.order_items.all? { |candidate| candidate.status == "billed" }
          order.update!(status: "billed")
        end
      end
    end
  end
end
