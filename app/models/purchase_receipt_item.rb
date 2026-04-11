class PurchaseReceiptItem < ApplicationRecord
  belongs_to :tenant
  belongs_to :purchase_receipt
  belongs_to :purchase_order_item
  belongs_to :product
  has_many :purchase_adjustments, dependent: :restrict_with_exception

  validates :received_quantity, :unit_cost, :amount, presence: true
  validates :received_quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_cost, :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :tenant_consistency

  before_validation :snapshot_sources
  before_validation :calculate_amount

  def returned_quantity
    purchase_adjustments.select(&:purchase_return?).sum(&:quantity)
  end

  def returnable_quantity
    received_quantity - returned_quantity
  end

  private

  def snapshot_sources
    self.product_code_snapshot ||= purchase_order_item&.product_code_snapshot || product&.code
    self.product_name_snapshot ||= purchase_order_item&.product_name_snapshot || product&.name
    self.unit_name_snapshot ||= purchase_order_item&.unit_name_snapshot || product&.unit_name
    self.unit_cost ||= purchase_order_item&.unit_cost || product&.standard_price || 0
  end

  def calculate_amount
    return if received_quantity.blank? || unit_cost.blank?

    self.amount = BigDecimal(received_quantity.to_s) * BigDecimal(unit_cost.to_s)
  end

  def tenant_consistency
    return if tenant_id.blank? || purchase_receipt.blank? || purchase_order_item.blank? || product.blank?

    mismatch = tenant_id != purchase_receipt.tenant_id
    mismatch ||= tenant_id != purchase_order_item.tenant_id
    mismatch ||= tenant_id != product.tenant_id
    errors.add(:tenant, "と入荷先の所属が一致しません") if mismatch
  end
end
