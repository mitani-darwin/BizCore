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
      raise ArgumentError, "消し込み金額を入力してください" if allocations.blank?

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

      raise OverAllocationError, "消し込み金額は0より大きく入力してください" if amount <= 0
      raise OverAllocationError, "別テナントの仕入請求書には消し込めません" if purchase_bill.tenant_id != supplier_payment.tenant_id
      raise OverAllocationError, "別の仕入先の請求書には消し込めません" if purchase_bill.supplier_id != supplier_payment.supplier_id
      raise OverAllocationError, "取消済みの仕入請求書には消し込めません" if purchase_bill.cancelled?
      raise OverAllocationError, "消し込み金額が未消込支払額を超えています" if amount > supplier_payment.unapplied_amount
      raise OverAllocationError, "消し込み金額が仕入請求残高を超えています" if amount > purchase_bill.outstanding_amount

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
