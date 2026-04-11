class PurchaseBillBatch < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :executed_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true

  has_many :purchase_bills, dependent: :restrict_with_exception

  enum :status, STATUSES

  generates_document_number :batch_number, prefix: "PCL"

  validates :batch_number, :closing_date, :billing_period_from, :billing_period_to, :bill_date, :status, presence: true
  validates :bill_count, :supplier_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :total_amount, numericality: true
  validate :tenant_consistency
  validate :period_range

  before_validation :set_defaults

  scope :recent, -> { order(closing_date: :desc, created_at: :desc, id: :desc) }
  scope :active, -> { where(status: "issued") }

  def cancellable?
    issued? && purchase_bills.none? { |purchase_bill| purchase_bill.supplier_payment_allocations.exists? }
  end

  def refresh_statistics!
    active_bills = purchase_bills.reject(&:cancelled?)
    update!(
      bill_count: active_bills.size,
      supplier_count: active_bills.map(&:supplier_id).uniq.size,
      total_amount: active_bills.sum { |purchase_bill| purchase_bill.total_amount.to_d }
    )
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.executed_at ||= Time.current
  end

  def tenant_consistency
    return if tenant_id.blank?

    mismatch = executed_by.present? && tenant_id != executed_by.tenant_id
    mismatch ||= cancelled_by.present? && tenant_id != cancelled_by.tenant_id
    errors.add(:tenant, "と実行者の所属が一致しません") if mismatch
  end

  def period_range
    return if billing_period_from.blank? || billing_period_to.blank?
    return if billing_period_from <= billing_period_to

    errors.add(:billing_period_to, "は請求期間開始以降で入力してください")
  end
end
