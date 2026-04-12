class PurchaseAdjustment < ApplicationRecord
  include DocumentNumbering

  TYPES = {
    purchase_return: "purchase_return",
    discount: "discount"
  }.freeze

  STATUSES = {
    issued: "issued",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :supplier
  belongs_to :warehouse
  belongs_to :purchase_order
  belongs_to :purchase_receipt
  belongs_to :purchase_receipt_item, optional: true
  belongs_to :product, optional: true
  has_many :purchase_bill_items, as: :source, dependent: :restrict_with_exception

  enum :adjustment_type, TYPES
  enum :status, STATUSES

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    left_outer_joins(:supplier, :purchase_receipt).where(
      <<~SQL.squish,
        purchase_adjustments.adjustment_number LIKE :pattern OR
        suppliers.name LIKE :pattern OR
        purchase_receipts.purchase_receipt_number LIKE :pattern OR
        purchase_adjustments.product_name_snapshot LIKE :pattern OR
        purchase_adjustments.reason LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_type, ->(adjustment_type) { adjustment_type.present? ? where(adjustment_type: adjustment_type) : all }
  scope :with_supplier, ->(supplier_id) { supplier_id.present? ? where(supplier_id: supplier_id) : all }
  scope :ordered_for_admin, -> { order(adjustment_date: :desc, id: :desc) }

  generates_document_number :adjustment_number, prefix: "ADJ"

  validates :adjustment_number, :adjustment_type, :adjustment_date, :status, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :unit_cost, :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency
  validate :return_fields
  validate :discount_fields

  before_validation :set_defaults
  before_validation :snapshot_product

  def display_quantity
    quantity.positive? ? quantity : nil
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.adjustment_date ||= Date.current
    self.issued_at ||= Time.current
  end

  def snapshot_product
    source_item = purchase_receipt_item
    source_product = product || source_item&.product

    self.product ||= source_product
    self.product_code_snapshot ||= source_item&.product_code_snapshot || source_product&.code
    self.product_name_snapshot ||= source_item&.product_name_snapshot || source_product&.name
    self.unit_name_snapshot ||= source_item&.unit_name_snapshot || source_product&.unit_name
    self.unit_cost ||= source_item&.unit_cost || 0
  end

  def tenant_consistency
    return if tenant_id.blank? || supplier.blank? || warehouse.blank? || purchase_order.blank? || purchase_receipt.blank?

    mismatch = tenant_id != supplier.tenant_id
    mismatch ||= tenant_id != warehouse.tenant_id
    mismatch ||= tenant_id != purchase_order.tenant_id
    mismatch ||= tenant_id != purchase_receipt.tenant_id
    mismatch ||= purchase_receipt.purchase_order_id != purchase_order_id
    mismatch ||= purchase_receipt.supplier_id != supplier_id
    mismatch ||= purchase_receipt.warehouse_id != warehouse_id
    mismatch ||= purchase_receipt_item.present? && purchase_receipt_item.purchase_receipt_id != purchase_receipt_id
    mismatch ||= product.present? && tenant_id != product.tenant_id
    errors.add(:tenant, "と返品/値引き対象の所属が一致しません") if mismatch
  end

  def return_fields
    return unless purchase_return?

    errors.add(:purchase_receipt_item, "を選択してください") if purchase_receipt_item.blank?
    errors.add(:product, "を選択してください") if product.blank?
    errors.add(:quantity, "は1以上で入力してください") if quantity.to_i <= 0
    errors.add(:amount, "は0より大きい必要があります") if amount.to_d <= 0
  end

  def discount_fields
    return unless discount?

    errors.add(:quantity, "は0である必要があります") if quantity.to_i.positive?
    errors.add(:amount, "は0より大きい必要があります") if amount.to_d <= 0
  end
end
