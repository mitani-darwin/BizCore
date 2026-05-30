# 発注に対する入荷票を表すモデル。発注（PurchaseOrder）1件に対して複数の入荷票が発生しうる。
# net_amount は入荷金額から返品・値引きを除いた実質金額を返す。
class PurchaseReceipt < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :supplier
  belongs_to :warehouse
  belongs_to :purchase_order

  has_many :purchase_receipt_items, dependent: :destroy
  has_many :purchase_adjustments, dependent: :restrict_with_exception

  enum :status, STATUSES

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    left_outer_joins(:supplier, :purchase_order).where(
      <<~SQL.squish,
        purchase_receipts.purchase_receipt_number LIKE :pattern OR
        suppliers.name LIKE :pattern OR
        purchase_orders.purchase_order_number LIKE :pattern OR
        purchase_receipts.received_by_name LIKE :pattern OR
        purchase_receipts.remarks LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_supplier, ->(supplier_id) { supplier_id.present? ? where(supplier_id: supplier_id) : all }
  scope :ordered_for_admin, -> { order(received_on: :desc, id: :desc) }

  generates_document_number :purchase_receipt_number, prefix: "RCV"

  validates :purchase_receipt_number, :received_on, :status, presence: true
  validate :tenant_consistency

  before_validation :set_defaults

  def total_amount
    purchase_receipt_items.sum { |item| item.amount.to_d }
  end

  def total_return_amount
    purchase_adjustments.select(&:purchase_return?).sum { |adjustment| adjustment.amount.to_d }
  end

  def total_discount_amount
    purchase_adjustments.select(&:discount?).sum { |adjustment| adjustment.amount.to_d }
  end

  def net_amount
    total_amount - total_return_amount - total_discount_amount
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.issued_at ||= Time.current
  end

  def tenant_consistency
    return if tenant_id.blank? || supplier.blank? || warehouse.blank? || purchase_order.blank?

    mismatch = tenant_id != supplier.tenant_id
    mismatch ||= tenant_id != warehouse.tenant_id
    mismatch ||= tenant_id != purchase_order.tenant_id
    errors.add(:tenant, "と仕入先/倉庫/発注の所属が一致しません") if mismatch
  end
end
