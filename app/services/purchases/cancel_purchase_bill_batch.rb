module Purchases
  class CancelPurchaseBillBatch
    def self.call(purchase_bill_batch:, cancelled_by: nil, cancelled_at: Time.current)
      new(purchase_bill_batch: purchase_bill_batch, cancelled_by: cancelled_by, cancelled_at: cancelled_at).call
    end

    def initialize(purchase_bill_batch:, cancelled_by:, cancelled_at:)
      @purchase_bill_batch = purchase_bill_batch
      @cancelled_by = cancelled_by
      @cancelled_at = cancelled_at
    end

    def call
      raise ArgumentError, "取消済みの締めバッチです" if purchase_bill_batch.cancelled?
      raise ArgumentError, "支払済みの仕入請求が含まれるため締め解除できません" unless purchase_bill_batch.cancellable?

      purchase_bill_batch.transaction do
        purchase_bill_batch.purchase_bills.where.not(status: "cancelled").find_each do |purchase_bill|
          Purchases::CancelPurchaseBill.call(
            purchase_bill: purchase_bill,
            cancelled_by: cancelled_by,
            cancelled_at: cancelled_at
          )
        end

        purchase_bill_batch.update!(
          status: "cancelled",
          cancelled_by: cancelled_by,
          cancelled_at: cancelled_at
        )
      end

      purchase_bill_batch
    end

    private

    attr_reader :purchase_bill_batch, :cancelled_by, :cancelled_at
  end
end
