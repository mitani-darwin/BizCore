module Purchases
  class IssueMonthlyBills
    class AlreadyClosedError < StandardError; end

    def self.call(tenant:, closing_date:, bill_date:, default_due_date: nil, billing_period_from: closing_date.beginning_of_month, billing_period_to: closing_date.end_of_month, requested_by: nil, note: nil)
      new(
        tenant: tenant,
        closing_date: closing_date,
        billing_period_from: billing_period_from,
        billing_period_to: billing_period_to,
        bill_date: bill_date,
        default_due_date: default_due_date,
        requested_by: requested_by,
        note: note
      ).call
    end

    def initialize(tenant:, closing_date:, billing_period_from:, billing_period_to:, bill_date:, default_due_date:, requested_by:, note:)
      @tenant = tenant
      @closing_date = closing_date
      @billing_period_from = billing_period_from
      @billing_period_to = billing_period_to
      @bill_date = bill_date
      @default_due_date = default_due_date
      @requested_by = requested_by
      @note = note
    end

    def call
      raise AlreadyClosedError, "この締め期間はすでに処理済みです" if active_batch.present?

      batch = nil
      grouped_items = grouped_billable_items

      tenant.transaction do
        batch = tenant.purchase_bill_batches.create!(
          executed_by: requested_by,
          closing_date: closing_date,
          billing_period_from: billing_period_from,
          billing_period_to: billing_period_to,
          bill_date: bill_date,
          default_due_date: default_due_date,
          note: note
        )

        grouped_items.each do |supplier, items|
          next if items.empty?

          purchase_bill = batch.purchase_bills.create!(
            tenant: tenant,
            supplier: supplier,
            closing_date: closing_date,
            billing_period_from: billing_period_from,
            billing_period_to: billing_period_to,
            bill_date: bill_date,
            due_date: supplier.due_date_for(closing_date: closing_date, default_due_date: default_due_date),
            closing_day_snapshot: supplier.effective_closing_day_for(closing_date),
            payment_due_rule_snapshot: supplier.payment_due_rule,
            payment_method_snapshot: supplier.payment_method,
            remarks: note
          )

          items.sort_by { |item| [ billable_date_for(item), item.id ] }.each do |item|
            create_bill_item!(purchase_bill, item)
          end

          purchase_bill.recalculate_totals!
        end

        batch.reload.refresh_statistics!
      end

      batch
    end

    private

    attr_reader :tenant, :closing_date, :billing_period_from, :billing_period_to, :bill_date, :default_due_date, :requested_by, :note

    def active_batch
      @active_batch ||= tenant.purchase_bill_batches.active.find_by(
        closing_date: closing_date,
        billing_period_from: billing_period_from,
        billing_period_to: billing_period_to
      )
    end

    def grouped_billable_items
      billable_items.group_by { |item| supplier_for(item) }
                    .select { |supplier, _items| supplier&.billing_closes_on?(closing_date) }
    end

    def billable_items
      billable_receipt_items.to_a + billable_adjustments.to_a
    end

    def billable_receipt_items
      PurchaseReceiptItem
        .includes(:purchase_bill_items, :purchase_order_item, :product, purchase_receipt: :supplier)
        .joins(:purchase_receipt)
        .where(
          tenant_id: tenant.id,
          purchase_receipts: {
            received_on: billing_period_from..billing_period_to,
            status: "issued"
          }
        )
        .where.not(id: active_billed_source_ids("PurchaseReceiptItem"))
    end

    def billable_adjustments
      PurchaseAdjustment
        .includes(:purchase_bill_items, :product, :purchase_receipt_item, :supplier, :purchase_receipt)
        .where(
          tenant_id: tenant.id,
          adjustment_date: billing_period_from..billing_period_to,
          status: "issued"
        )
        .where.not(id: active_billed_source_ids("PurchaseAdjustment"))
    end

    def active_billed_source_ids(source_type)
      PurchaseBillItem.active_for_source.where(tenant_id: tenant.id, source_type: source_type).select(:source_id)
    end

    def billable_date_for(item)
      case item
      when PurchaseReceiptItem
        item.purchase_receipt.received_on
      when PurchaseAdjustment
        item.adjustment_date
      else
        Date.current
      end
    end

    def supplier_for(item)
      case item
      when PurchaseReceiptItem
        item.purchase_receipt.supplier
      when PurchaseAdjustment
        item.supplier
      end
    end

    def create_bill_item!(purchase_bill, item)
      case item
      when PurchaseReceiptItem
        purchase_bill.purchase_bill_items.create!(
          tenant: tenant,
          source: item,
          description: "#{item.product_name_snapshot} (#{item.purchase_receipt.purchase_receipt_number})",
          quantity: item.received_quantity,
          unit_price: item.unit_cost,
          tax_category: item.purchase_order_item.tax_category_snapshot
        )
      when PurchaseAdjustment
        purchase_bill.purchase_bill_items.create!(
          tenant: tenant,
          source: item,
          description: purchase_adjustment_description(item),
          quantity: item.purchase_return? ? item.quantity : 1,
          unit_price: purchase_adjustment_unit_price(item),
          tax_category: purchase_adjustment_tax_category(item)
        )
      end
    end

    def purchase_adjustment_description(adjustment)
      label = adjustment.purchase_return? ? "返品" : "値引き"
      target = adjustment.product_name_snapshot.presence || adjustment.reason.presence || "調整"
      "#{label} #{target} (#{adjustment.adjustment_number})"
    end

    def purchase_adjustment_unit_price(adjustment)
      return -adjustment.unit_cost.to_d if adjustment.purchase_return?

      -adjustment.amount.to_d
    end

    def purchase_adjustment_tax_category(adjustment)
      adjustment.purchase_receipt_item&.purchase_order_item&.tax_category_snapshot ||
        adjustment.product&.tax_category ||
        adjustment.purchase_receipt.purchase_receipt_items.first&.purchase_order_item&.tax_category_snapshot ||
        "taxable_10"
    end
  end
end
