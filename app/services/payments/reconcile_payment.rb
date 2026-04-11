module Payments
  class ReconcilePayment
    class OverAllocationError < StandardError; end

    def self.call(payment:, allocations:)
      new(payment:, allocations:).call
    end

    def initialize(payment:, allocations:)
      @payment = payment
      @allocations = allocations
    end

    def call
      raise ArgumentError, "allocations are required" if allocations.blank?

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

      raise OverAllocationError, "allocation amount must be positive" if amount <= 0
      raise OverAllocationError, "invoice belongs to another tenant" if invoice.tenant_id != payment.tenant_id
      raise OverAllocationError, "invoice belongs to another customer" if invoice.customer_id != payment.customer_id
      raise OverAllocationError, "allocation exceeds unapplied payment amount" if amount > payment.unapplied_amount
      raise OverAllocationError, "allocation exceeds invoice balance" if amount > invoice.outstanding_amount

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
