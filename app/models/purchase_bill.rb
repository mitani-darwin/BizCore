class PurchaseBill < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    partially_paid: "partially_paid",
    paid: "paid",
    credit: "credit",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :supplier
  belongs_to :purchase_bill_batch, optional: true
  belongs_to :reissued_from, class_name: "PurchaseBill", optional: true

  has_many :purchase_bill_items, dependent: :destroy
  has_many :supplier_payment_allocations, dependent: :destroy
  has_many :supplier_payments, through: :supplier_payment_allocations
  has_many :reissues, class_name: "PurchaseBill", foreign_key: :reissued_from_id, dependent: :nullify, inverse_of: :reissued_from

  enum :status, STATUSES

  generates_document_number :bill_number, prefix: "PBL"

  validates :bill_number, :closing_date, :billing_period_from, :billing_period_to, :bill_date, :due_date, :status, presence: true
  validates :subtotal_amount, :tax_amount, :total_amount, :balance_amount, numericality: true
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :set_defaults

  def recalculate_totals!
    line_items = purchase_bill_items.reload
    allocations = supplier_payment_allocations.reload

    subtotal = line_items.sum { |item| item.amount.to_d }
    tax = line_items.sum(&:tax_amount)
    total = subtotal + tax
    paid = allocations.sum { |allocation| allocation.allocated_amount.to_d }
    balance = total - paid

    update!(
      subtotal_amount: subtotal,
      tax_amount: tax,
      total_amount: total,
      paid_amount: paid,
      balance_amount: balance,
      status: bill_status_for(total, balance, paid)
    )
  end

  def outstanding_amount
    return 0.to_d if cancelled?

    [balance_amount.to_d, 0.to_d].max
  end

  def cancellable?
    !cancelled? && supplier_payment_allocations.empty?
  end

  def reissuable?
    cancelled? &&
      reissues.where.not(status: "cancelled").none? &&
      purchase_bill_items.none? { |item| item.source.present? && item.source.purchase_bill_items.active_for_source.exists? }
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.closing_day_snapshot ||= supplier&.effective_closing_day_for(closing_date || Date.current)
    self.payment_due_rule_snapshot ||= supplier&.payment_due_rule
    self.payment_method_snapshot ||= supplier&.payment_method
    self.subtotal_amount ||= 0
    self.tax_amount ||= 0
    self.total_amount ||= 0
    self.paid_amount ||= 0
    self.balance_amount ||= total_amount
  end

  def bill_status_for(total, balance, paid)
    return "credit" if total <= 0
    return "paid" if balance <= 0
    return "partially_paid" if paid.positive?

    "issued"
  end

  def tenant_consistency
    return if tenant_id.blank? || supplier.blank?

    mismatch = tenant_id != supplier.tenant_id
    mismatch ||= purchase_bill_batch.present? && tenant_id != purchase_bill_batch.tenant_id
    mismatch ||= reissued_from.present? && tenant_id != reissued_from.tenant_id
    errors.add(:tenant, "と仕入先の所属が一致しません") if mismatch
  end
end
