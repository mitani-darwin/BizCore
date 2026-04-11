class Delivery < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    issued: "issued",
    billed: "billed",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :order
  belongs_to :customer

  has_many :delivery_items, dependent: :destroy

  enum :status, STATUSES

  generates_document_number :delivery_number, prefix: "DLV"

  validates :delivery_number, :delivery_date, :status, presence: true
  validate :tenant_consistency

  before_validation :set_defaults

  def total_amount
    delivery_items.sum { |item| item.amount.to_d }
  end

  private

  def set_defaults
    self.status ||= "issued"
    self.issued_at ||= Time.current
    self.delivery_address ||= order&.delivery_address || customer&.full_address
  end

  def tenant_consistency
    return if tenant_id.blank? || order.blank? || customer.blank?

    if tenant_id != order.tenant_id || tenant_id != customer.tenant_id
      errors.add(:tenant, "と注文/取引先の所属が一致しません")
    end
  end
end
