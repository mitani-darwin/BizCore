# 受注（販売注文）を表すモデル。draft → sent → accepted → allocated → delivered → billed の順で進む。
# 見積（Quotation）から変換して作成する場合と、直接作成する場合がある。
class Order < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    draft: "draft",
    sent: "sent",
    accepted: "accepted",
    allocated: "allocated",
    delivered: "delivered",
    billed: "billed",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :customer
  belongs_to :quotation, optional: true

  has_many :order_items, dependent: :destroy
  has_many :deliveries, dependent: :restrict_with_exception

  enum :status, STATUSES

  accepts_nested_attributes_for :order_items, allow_destroy: true

  generates_document_number :order_number, prefix: "ORD"

  validates :order_number, :order_date, :status, presence: true
  validate :tenant_consistency

  before_validation :set_defaults

  def total_amount
    order_items.sum { |item| item.amount.to_d }
  end

  def mark_as_sent!(sent_at: Time.current)
    raise ArgumentError, "注文明細がありません" if order_items.empty?
    raise ArgumentError, "下書き状態の注文のみ送信できます" unless draft?

    update!(status: "sent", sent_at: sent_at)
  end

  def mark_as_accepted!(accepted_at: Time.current)
    raise ArgumentError, "送信済みの注文のみ受注確定できます" unless sent?

    update!(status: "accepted", accepted_at: accepted_at)
  end

  private

  def set_defaults
    self.order_date ||= Date.current
    self.status ||= "draft"
    self.delivery_address ||= customer&.full_address
  end

  def tenant_consistency
    return if tenant_id.blank? || customer.blank?

    mismatch = tenant_id != customer.tenant_id
    mismatch ||= quotation.present? && (tenant_id != quotation.tenant_id || customer_id != quotation.customer_id)

    errors.add(:tenant, "と取引先の所属が一致しません") if mismatch
  end
end
