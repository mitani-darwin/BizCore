module Purchases
  # 個別の仕入請求書を取消するサービス。支払消し込み済みの場合は取消不可。
  class CancelPurchaseBill
    def self.call(purchase_bill:, cancelled_by: nil, cancelled_at: Time.current)
      new(purchase_bill: purchase_bill, cancelled_by: cancelled_by, cancelled_at: cancelled_at).call
    end

    def initialize(purchase_bill:, cancelled_by:, cancelled_at:)
      @purchase_bill = purchase_bill
      @cancelled_by = cancelled_by
      @cancelled_at = cancelled_at
    end

    def call
      raise ArgumentError, "すでに取消済みの仕入請求書です" if purchase_bill.cancelled?
      raise ArgumentError, "支払済みの仕入請求書は取消できません" if purchase_bill.supplier_payment_allocations.exists?

      purchase_bill.transaction do
        purchase_bill.update!(status: "cancelled", cancelled_at: cancelled_at)
        purchase_bill.purchase_bill_batch&.reload&.refresh_statistics!
      end

      purchase_bill
    end

    private

    attr_reader :purchase_bill, :cancelled_by, :cancelled_at
  end
end
