module Purchases
  # キャンセル済み仕入請求書を再発行するサービス。ReissueInvoice の仕入側に対応する。
  class ReissuePurchaseBill
    def self.call(purchase_bill:, bill_date: Date.current, default_due_date: nil)
      new(purchase_bill: purchase_bill, bill_date: bill_date, default_due_date: default_due_date).call
    end

    def initialize(purchase_bill:, bill_date:, default_due_date:)
      @purchase_bill = purchase_bill
      @bill_date = bill_date
      @default_due_date = default_due_date
    end

    def call
      raise ArgumentError, "取消済みの仕入請求書のみ再発行できます" unless purchase_bill.cancelled?
      raise ArgumentError, "すでに再発行済みの仕入請求書です" if purchase_bill.reissues.where.not(status: "cancelled").exists?
      raise ArgumentError, "同じ入荷明細の仕入請求がすでに有効です" if active_source_bill_exists?

      reissued_bill = nil

      purchase_bill.transaction do
        reissued_bill = purchase_bill.tenant.purchase_bills.create!(
          purchase_bill_batch: purchase_bill.purchase_bill_batch,
          reissued_from: purchase_bill,
          supplier: purchase_bill.supplier,
          closing_date: purchase_bill.closing_date,
          billing_period_from: purchase_bill.billing_period_from,
          billing_period_to: purchase_bill.billing_period_to,
          bill_date: bill_date,
          due_date: purchase_bill.supplier.due_date_for(
            closing_date: purchase_bill.closing_date,
            default_due_date: default_due_date || purchase_bill.due_date
          ),
          closing_day_snapshot: purchase_bill.closing_day_snapshot,
          payment_due_rule_snapshot: purchase_bill.payment_due_rule_snapshot,
          payment_method_snapshot: purchase_bill.payment_method_snapshot,
          remarks: [ purchase_bill.remarks.presence, "再発行元: #{purchase_bill.bill_number}" ].compact.join("\n")
        )

        purchase_bill.purchase_bill_items.find_each do |item|
          reissued_bill.purchase_bill_items.create!(
            tenant: purchase_bill.tenant,
            source: item.source,
            description: item.description,
            quantity: item.quantity,
            unit_price: item.unit_price,
            tax_category: item.tax_category
          )
        end

        reissued_bill.recalculate_totals!
        purchase_bill.purchase_bill_batch&.reload&.refresh_statistics!
      end

      reissued_bill
    end

    private

    attr_reader :purchase_bill, :bill_date, :default_due_date

    def active_source_bill_exists?
      purchase_bill.purchase_bill_items.any? do |item|
        item.source.present? && item.source.purchase_bill_items.active_for_source.exists?
      end
    end
  end
end
