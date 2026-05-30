# 月次請求締め処理のバッチを表すモデル。
# 1 回の締め処理で複数の請求書（Invoice）を一括発行する。
# cancellable? は消し込み済み入金がない場合のみ true を返す（締め解除の前提条件）。
class BillingBatch < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :executed_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true

  has_many :invoices, dependent: :restrict_with_exception

  enum :status, STATUSES

  generates_document_number :batch_number, prefix: "BCL"

  validates :batch_number, :closing_date, :billing_period_from, :billing_period_to, :invoice_date, :status, presence: true
  validates :invoice_count, :customer_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency
  validate :period_range

  before_validation :set_defaults

  scope :recent, -> { order(closing_date: :desc, created_at: :desc, id: :desc) }
  scope :active, -> { where(status: "issued") }

  def cancellable?
    issued? && invoices.none? { |invoice| invoice.payment_allocations.exists? }
  end

  def refresh_statistics!
    active_invoices = invoices.reject(&:cancelled?)
    update!(
      invoice_count: active_invoices.size,
      customer_count: active_invoices.map(&:customer_id).uniq.size,
      total_amount: active_invoices.sum { |invoice| invoice.total_amount.to_d }
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
