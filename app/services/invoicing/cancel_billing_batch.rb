module Invoicing
  class CancelBillingBatch
    def self.call(billing_batch:, cancelled_by: nil, cancelled_at: Time.current)
      new(billing_batch: billing_batch, cancelled_by: cancelled_by, cancelled_at: cancelled_at).call
    end

    def initialize(billing_batch:, cancelled_by:, cancelled_at:)
      @billing_batch = billing_batch
      @cancelled_by = cancelled_by
      @cancelled_at = cancelled_at
    end

    def call
      raise ArgumentError, "取消済みの締めバッチです" if billing_batch.cancelled?
      raise ArgumentError, "入金済みの請求が含まれるため締め解除できません" unless billing_batch.cancellable?

      billing_batch.transaction do
        billing_batch.invoices.where.not(status: "cancelled").find_each do |invoice|
          Invoicing::CancelInvoice.call(invoice: invoice, cancelled_by: cancelled_by, cancelled_at: cancelled_at)
        end

        billing_batch.update!(
          status: "cancelled",
          cancelled_by: cancelled_by,
          cancelled_at: cancelled_at
        )
      end

      billing_batch
    end

    private

    attr_reader :billing_batch, :cancelled_by, :cancelled_at
  end
end
