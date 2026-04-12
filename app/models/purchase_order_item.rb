class PurchaseOrderItem < ApplicationRecord
  STATUSES = {
    pending: "pending",
    partially_received: "partially_received",
    received: "received",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :purchase_order
  belongs_to :product

  has_many :purchase_receipt_items, dependent: :restrict_with_exception

  enum :status, STATUSES

  validates :line_no, :quantity, :unit_cost, :amount, :status, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :received_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :unit_cost, :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :line_no, uniqueness: { scope: :purchase_order_id }
  validate :tenant_consistency
  validate :received_quantity_must_not_exceed_ordered

  before_validation :set_defaults
  before_validation :inherit_tenant
  before_validation :snapshot_product
  before_validation :calculate_amount

  def remaining_quantity
    quantity - received_quantity
  end

  def register_receipt!(quantity)
    qty = quantity.to_i
    raise ArgumentError, "receipt quantity must be positive" if qty <= 0
    raise ArgumentError, "receipt quantity exceeds remaining quantity" if qty > remaining_quantity

    new_received_quantity = received_quantity + qty
    update!(
      received_quantity: new_received_quantity,
      status: status_for(new_received_quantity)
    )
  end

  private

  def set_defaults
    self.line_no ||= next_line_no
    self.status ||= "pending"
    self.received_quantity ||= 0
    self.unit_cost ||= product&.standard_price || 0
  end

  def inherit_tenant
    self.tenant ||= purchase_order&.tenant
  end

  def snapshot_product
    return unless product

    self.product_code_snapshot ||= product.code
    self.product_name_snapshot ||= product.name
    self.unit_name_snapshot ||= product.unit_name
    self.tax_category_snapshot ||= product.tax_category
  end

  def calculate_amount
    return if quantity.blank? || unit_cost.blank?

    self.amount = BigDecimal(quantity.to_s) * BigDecimal(unit_cost.to_s)
  end

  def next_line_no
    return 1 unless purchase_order

    existing = purchase_order.purchase_order_items.reject { |item| item.equal?(self) }
    existing.map(&:line_no).compact.max.to_i + 1
  end

  def status_for(received_qty)
    return "received" if received_qty >= quantity
    return "partially_received" if received_qty.positive?

    "pending"
  end

  def tenant_consistency
    return if tenant_id.blank? || purchase_order.blank? || product.blank?

    if tenant_id != purchase_order.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と発注/商品の所属が一致しません")
    end
  end

  def received_quantity_must_not_exceed_ordered
    return if quantity.blank? || received_quantity.blank?
    return if received_quantity <= quantity

    errors.add(:received_quantity, "は発注数量以下である必要があります")
  end
end
