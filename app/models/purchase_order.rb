# 発注書を表すモデル。draft → sent → partially_received → received の順で入荷状況が更新される。
# refresh_receipt_status! は入荷処理後に呼び出してステータスを自動更新する。
class PurchaseOrder < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    draft: "draft",
    sent: "sent",
    partially_received: "partially_received",
    received: "received",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :supplier
  belongs_to :warehouse

  has_many :purchase_order_items, dependent: :destroy
  has_many :purchase_receipts, dependent: :restrict_with_exception
  has_many :purchase_adjustments, dependent: :restrict_with_exception

  enum :status, STATUSES

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    left_outer_joins(:supplier).where(
      <<~SQL.squish,
        purchase_orders.purchase_order_number LIKE :pattern OR
        suppliers.name LIKE :pattern OR
        purchase_orders.ordered_by_name LIKE :pattern OR
        purchase_orders.remarks LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :with_supplier, ->(supplier_id) { supplier_id.present? ? where(supplier_id: supplier_id) : all }
  scope :ordered_for_admin, -> { order(order_date: :desc, id: :desc) }

  accepts_nested_attributes_for :purchase_order_items, allow_destroy: true

  generates_document_number :purchase_order_number, prefix: "PO"

  validates :purchase_order_number, :order_date, :status, presence: true
  validate :tenant_consistency

  before_validation :set_defaults

  def total_amount
    purchase_order_items.sum { |item| item.amount.to_d }
  end

  def total_received_quantity
    purchase_order_items.sum(&:received_quantity)
  end

  def total_remaining_quantity
    purchase_order_items.sum(&:remaining_quantity)
  end

  def total_return_amount
    purchase_adjustments.select(&:purchase_return?).sum { |adjustment| adjustment.amount.to_d }
  end

  def total_discount_amount
    purchase_adjustments.select(&:discount?).sum { |adjustment| adjustment.amount.to_d }
  end

  def receivable?
    sent? || partially_received?
  end

  def mark_as_sent!(sent_at: Time.current)
    raise ArgumentError, "発注明細がありません" if purchase_order_items.empty?
    raise ArgumentError, "下書き状態の発注のみ送信できます" unless draft?

    update!(status: "sent", sent_at: sent_at)
  end

  def refresh_receipt_status!
    new_status =
      if purchase_order_items.all?(&:received?)
        "received"
      elsif purchase_order_items.any? { |item| item.received_quantity.positive? }
        "partially_received"
      elsif sent_at.present?
        "sent"
      else
        "draft"
      end

    update!(status: new_status)
  end

  private

  def set_defaults
    self.order_date ||= Date.current
    self.status ||= "draft"
  end

  def tenant_consistency
    return if tenant_id.blank? || supplier.blank? || warehouse.blank?

    mismatch = tenant_id != supplier.tenant_id
    mismatch ||= tenant_id != warehouse.tenant_id
    errors.add(:tenant, "と仕入先/倉庫の所属が一致しません") if mismatch
  end
end
