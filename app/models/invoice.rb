# 請求書を表すモデル。issued → partially_paid → paid の順でステータスが変化する。
# 消し込み（PaymentAllocation）が追加・削除されるたびに recalculate_totals! で金額を再集計する。
# 取消（cancelled）後は再発行（reissue）が可能だが、既に別の再発行がある場合は不可。
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
  belongs_to :billing_batch, optional: true
  belongs_to :reissued_from, class_name: "Invoice", optional: true

  has_many :invoice_items, dependent: :destroy
  has_many :payment_allocations, dependent: :destroy
  has_many :reissues, class_name: "Invoice", foreign_key: :reissued_from_id, dependent: :nullify, inverse_of: :reissued_from

  enum :status, STATUSES

  generates_document_number :invoice_number, prefix: "INV"

  validates :invoice_number, :closing_date, :billing_period_from, :billing_period_to, :invoice_date, :due_date, :status, presence: true
  validates :subtotal_amount, :tax_amount, :total_amount, :paid_amount, :balance_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :set_defaults

  # 明細と消し込みを再集計してステータスを更新する。
  # 入金消し込みの追加・削除後に必ず呼び出す必要がある。
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
    return 0.to_d if cancelled?

    total_amount.to_d - paid_amount.to_d
  end

  def cancellable?
    !cancelled? && payment_allocations.empty?
  end

  def reissuable?
    cancelled? &&
      reissues.where.not(status: "cancelled").none? &&
      invoice_items.none? { |item| item.source.present? && item.source.invoice_items.active_for_source.exists? }
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.closing_day_snapshot ||= customer&.effective_closing_day_for(closing_date || Date.current)
    self.payment_due_rule_snapshot ||= customer&.payment_due_rule
    self.invoice_delivery_method_snapshot ||= customer&.invoice_delivery_method
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

    mismatch = tenant_id != customer.tenant_id
    mismatch ||= billing_batch.present? && tenant_id != billing_batch.tenant_id
    mismatch ||= reissued_from.present? && tenant_id != reissued_from.tenant_id
    errors.add(:tenant, "と取引先の所属が一致しません") if mismatch
  end
end
