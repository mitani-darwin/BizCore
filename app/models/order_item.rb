class OrderItem < ApplicationRecord
  STATUSES = {
    pending: "pending",
    allocated: "allocated",
    delivered: "delivered",
    billed: "billed",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :order
  belongs_to :product

  has_many :stock_allocations, dependent: :restrict_with_exception
  has_many :delivery_items, dependent: :restrict_with_exception

  enum :status, STATUSES

  validates :line_no, :quantity, :unit_price, :amount, :status, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :line_no, uniqueness: { scope: :order_id }
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :snapshot_product
  before_validation :calculate_amount

  def allocated_quantity
    stock_allocations.where(status: %w[reserved consumed]).sum(:allocated_quantity)
  end

  def delivered_quantity
    delivery_items.sum(:delivered_quantity)
  end

  def remaining_to_allocate
    quantity - allocated_quantity
  end

  def remaining_to_deliver
    quantity - delivered_quantity
  end

  private

  def set_defaults
    self.line_no ||= next_line_no
    self.status ||= "pending"
    self.unit_price ||= product&.standard_price || 0
  end

  def snapshot_product
    return unless product

    self.product_code_snapshot ||= product.code
    self.product_name_snapshot ||= product.name
    self.unit_name_snapshot ||= product.unit_name
    self.tax_category_snapshot ||= product.tax_category
  end

  def calculate_amount
    return if quantity.blank? || unit_price.blank?

    self.amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
  end

  def next_line_no
    return 1 unless order

    existing = order.order_items.reject { |item| item.equal?(self) }
    existing.map(&:line_no).compact.max.to_i + 1
  end

  def tenant_consistency
    return if tenant_id.blank? || order.blank? || product.blank?

    if tenant_id != order.tenant_id || tenant_id != product.tenant_id
      errors.add(:tenant, "と注文/商品の所属が一致しません")
    end
  end
end
