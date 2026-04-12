module Purchases
  class ReconcileSupplierPayment
    class OverAllocationError < StandardError; end

    def self.call(supplier_payment:, allocations:)
      new(supplier_payment: supplier_payment, allocations: allocations).call
    end

    def initialize(supplier_payment:, allocations:)
      @supplier_payment = supplier_payment
      @allocations = allocations
    end

    def call
      raise ArgumentError, "allocations are required" if allocations.blank?

      supplier_payment.transaction do
        allocations.each do |entry|
          apply_allocation!(entry)
        end

        supplier_payment.update!(status: supplier_payment.status_for_current_allocations)
      end

      supplier_payment
    end

    private

    attr_reader :supplier_payment, :allocations

    def apply_allocation!(entry)
      purchase_bill = entry.fetch(:purchase_bill)
      amount = BigDecimal(entry.fetch(:amount).to_s)

      raise OverAllocationError, "allocation amount must be positive" if amount <= 0
      raise OverAllocationError, "purchase bill belongs to another tenant" if purchase_bill.tenant_id != supplier_payment.tenant_id
      raise OverAllocationError, "purchase bill belongs to another supplier" if purchase_bill.supplier_id != supplier_payment.supplier_id
      raise OverAllocationError, "cancelled purchase bill cannot be allocated" if purchase_bill.cancelled?
      raise OverAllocationError, "allocation exceeds unapplied payment amount" if amount > supplier_payment.unapplied_amount
      raise OverAllocationError, "allocation exceeds purchase bill balance" if amount > purchase_bill.outstanding_amount

      allocation = SupplierPaymentAllocation.find_or_initialize_by(
        tenant: supplier_payment.tenant,
        supplier_payment: supplier_payment,
        purchase_bill: purchase_bill
      )
      allocation.allocated_amount = allocation.allocated_amount.to_d + amount
      allocation.save!

      purchase_bill.recalculate_totals!
    end
  end
end
