module Invoicing
  # 月次請求締め処理を実行するサービス。
  # 納品済み（billed でない）明細を締め日ごとに集計し、得意先ごとに Invoice を一括生成する。
  # 同じ締め日で既に BillingBatch が存在する場合は AlreadyClosedError を上げる。
  class IssueMonthlyInvoices
    # 二重締めを防ぐカスタム例外。
    class AlreadyClosedError < StandardError; end

    def self.call(tenant:, closing_date:, invoice_date:, default_due_date: nil, billing_period_from: closing_date.beginning_of_month, billing_period_to: closing_date.end_of_month, requested_by: nil, note: nil)
      new(
        tenant: tenant,
        closing_date: closing_date,
        billing_period_from: billing_period_from,
        billing_period_to: billing_period_to,
        invoice_date: invoice_date,
        default_due_date: default_due_date,
        requested_by: requested_by,
        note: note
      ).call
    end

    def initialize(tenant:, closing_date:, billing_period_from:, billing_period_to:, invoice_date:, default_due_date:, requested_by:, note:)
      @tenant = tenant
      @closing_date = closing_date
      @billing_period_from = billing_period_from
      @billing_period_to = billing_period_to
      @invoice_date = invoice_date
      @default_due_date = default_due_date
      @requested_by = requested_by
      @note = note
    end

    def call
      raise AlreadyClosedError, "この締め期間はすでに処理済みです" if active_batch.present?

      batch = nil
      grouped_items = grouped_billable_items

      tenant.transaction do
        batch = tenant.billing_batches.create!(
          executed_by: requested_by,
          closing_date: closing_date,
          billing_period_from: billing_period_from,
          billing_period_to: billing_period_to,
          invoice_date: invoice_date,
          default_due_date: default_due_date,
          note: note
        )

        grouped_items.each do |customer, items|
          next if items.empty?

          invoice = batch.invoices.create!(
            tenant: tenant,
            customer: customer,
            closing_date: closing_date,
            billing_period_from: billing_period_from,
            billing_period_to: billing_period_to,
            invoice_date: invoice_date,
            due_date: customer.due_date_for(closing_date: closing_date, default_due_date: default_due_date),
            closing_day_snapshot: customer.effective_closing_day_for(closing_date),
            payment_due_rule_snapshot: customer.payment_due_rule,
            invoice_delivery_method_snapshot: customer.invoice_delivery_method,
            remarks: note
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
        end

        batch.reload.refresh_statistics!
      end

      batch
    end

    private

    attr_reader :tenant, :closing_date, :billing_period_from, :billing_period_to, :invoice_date, :default_due_date, :requested_by, :note

    def active_batch
      @active_batch ||= tenant.billing_batches.active.find_by(
        closing_date: closing_date,
        billing_period_from: billing_period_from,
        billing_period_to: billing_period_to
      )
    end

    def grouped_billable_items
      billable_items.group_by { |item| item.delivery.customer }
                    .select { |customer, _items| customer.billing_closes_on?(closing_date) }
    end

    def billable_items
      DeliveryItem
        .includes(:invoice_items, :order_item, delivery: :customer)
        .joins(:delivery)
        .where(
          tenant_id: tenant.id,
          deliveries: {
            delivery_date: billing_period_from..billing_period_to,
            status: %w[issued billed]
          }
        )
        .where.not(id: active_billed_source_ids)
    end

    def active_billed_source_ids
      InvoiceItem.active_for_source.where(tenant_id: tenant.id, source_type: "DeliveryItem").select(:source_id)
    end

    def mark_sources_as_billed!(items)
      items.each do |item|
        refresh_delivery_status!(item.delivery)
        refresh_order_item_status!(item.order_item)
      end
    end

    def refresh_delivery_status!(delivery)
      next_status = delivery.delivery_items.all? { |delivery_item| actively_invoiced?(delivery_item) } ? "billed" : "issued"
      delivery.update!(status: next_status)
    end

    def refresh_order_item_status!(order_item)
      next_status = order_item.delivery_items.all? { |delivery_item| actively_invoiced?(delivery_item) } ? "billed" : "delivered"
      order_item.update!(status: next_status)

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

    def actively_invoiced?(delivery_item)
      delivery_item.invoice_items.active_for_source.exists?
    end
  end
end
