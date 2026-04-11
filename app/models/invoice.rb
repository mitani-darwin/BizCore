class Invoice < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    partially_paid: "partially_paid",
    paid: "paid",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :customer

  has_many :invoice_items, dependent: :destroy
  has_many :payment_allocations, dependent: :destroy

  enum :status, STATUSES

  generates_document_number :invoice_number, prefix: "INV"

  validates :invoice_number, :closing_date, :billing_period_from, :billing_period_to, :invoice_date, :due_date, :status, presence: true
  validates :subtotal_amount, :tax_amount, :total_amount, :paid_amount, :balance_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :set_defaults

  def recalculate_totals!
    line_items = invoice_items.reload
    allocations = payment_allocations.reload

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
      status: invoice_status_for(balance, paid)
    )
  end

  def outstanding_amount
    total_amount.to_d - paid_amount.to_d
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.subtotal_amount ||= 0
    self.tax_amount ||= 0
    self.total_amount ||= 0
    self.paid_amount ||= 0
    self.balance_amount ||= total_amount
  end

  def invoice_status_for(balance, paid)
    balance <= 0 ? "paid" : (paid.positive? ? "partially_paid" : "issued")
  end

  def tenant_consistency
    return if tenant_id.blank? || customer.blank?

    errors.add(:tenant, "と取引先の所属が一致しません") if tenant_id != customer.tenant_id
  end
end
