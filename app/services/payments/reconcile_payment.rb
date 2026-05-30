module Payments
  # 入金を請求書に消し込むサービス。PaymentAllocation を作成し、Invoice の金額を再計算する。
  # 消し込み額が入金額を超える場合は OverAllocationError を上げる。
  class ReconcilePayment
    # 消し込み額が入金額を超えた場合に上げる例外。
    class OverAllocationError < StandardError; end

    def self.call(payment:, allocations:)
      new(payment:, allocations:).call
    end

    def initialize(payment:, allocations:)
      @payment = payment
      @allocations = allocations
    end

    def call
      raise ArgumentError, "消し込み金額を入力してください" if allocations.blank?

      payment.transaction do
        allocations.each do |entry|
          apply_allocation!(entry)
        end

        payment.update!(status: payment.status_for_current_allocations)
      end

      payment
    end

    private

    attr_reader :payment, :allocations

    def apply_allocation!(entry)
      invoice = entry.fetch(:invoice)
      amount = BigDecimal(entry.fetch(:amount).to_s)

      raise OverAllocationError, "消し込み金額は0より大きく入力してください" if amount <= 0
      raise OverAllocationError, "別テナントの請求書には消し込めません" if invoice.tenant_id != payment.tenant_id
      raise OverAllocationError, "別の得意先の請求書には消し込めません" if invoice.customer_id != payment.customer_id
      raise OverAllocationError, "取消済みの請求書には消し込めません" if invoice.cancelled?
      raise OverAllocationError, "消し込み金額が未消込入金額を超えています" if amount > payment.unapplied_amount
      raise OverAllocationError, "消し込み金額が請求残高を超えています" if amount > invoice.outstanding_amount

      allocation = PaymentAllocation.find_or_initialize_by(
        tenant: payment.tenant,
        payment: payment,
        invoice: invoice
      )
      allocation.allocated_amount = allocation.allocated_amount.to_d + amount
      allocation.save!

      invoice.recalculate_totals!
    end
  end
end
