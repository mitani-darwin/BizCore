class Payment < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    pending: "pending",
    partially_applied: "partially_applied",
    applied: "applied",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :customer

  has_many :payment_allocations, dependent: :destroy
  has_many :invoices, through: :payment_allocations

  enum :status, STATUSES

  generates_document_number :payment_number, prefix: "PAY"

  validates :payment_number, :payment_date, :amount, :status, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validate :tenant_consistency
  validate :amount_must_cover_allocations

  before_validation :set_defaults

  def allocated_amount
    payment_allocations.sum(:allocated_amount).to_d
  end

  def unapplied_amount
    amount.to_d - allocated_amount
  end

  def status_for_current_allocations
    return "applied" if unapplied_amount <= 0
    return "partially_applied" if allocated_amount.positive?

    "pending"
  end

  private

  def set_defaults
    self.status ||= "pending"
  end

  def tenant_consistency
    return if tenant_id.blank? || customer.blank?

    errors.add(:tenant, "と取引先の所属が一致しません") if tenant_id != customer.tenant_id
  end

  def amount_must_cover_allocations
    return if amount.blank?
    return if amount.to_d >= allocated_amount

    errors.add(:amount, "は消込済金額以上である必要があります")
  end
end
