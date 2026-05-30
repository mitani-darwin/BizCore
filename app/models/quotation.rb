# 見積書を表すモデル。draft → sent → accepted → converted の順でステータスが遷移する。
# accepted になった見積を注文（Order）に変換する際は converted に更新する。
class Quotation < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    draft: "draft",
    sent: "sent",
    accepted: "accepted",
    converted: "converted",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :customer

  has_many :quotation_items, dependent: :destroy
  has_many :orders, dependent: :nullify

  enum :status, STATUSES

  accepts_nested_attributes_for :quotation_items, allow_destroy: true

  generates_document_number :quotation_number, prefix: "QUO"

  validates :quotation_number, :quotation_date, :expiration_date, :status, presence: true
  validate :tenant_consistency

  before_validation :set_defaults

  def subtotal_amount
    quotation_items.sum { |item| item.amount.to_d }
  end

  def tax_amount
    quotation_items.sum(&:tax_amount)
  end

  def total_amount
    subtotal_amount + tax_amount
  end

  def mark_as_sent!(sent_at: Time.current)
    raise ArgumentError, "見積明細がありません" if quotation_items.empty?
    raise ArgumentError, "下書き状態の見積のみ送信できます" unless draft?

    update!(status: "sent", sent_at: sent_at)
  end

  def mark_as_accepted!(accepted_at: Time.current)
    raise ArgumentError, "送信済みの見積のみ採用できます" unless sent?

    update!(status: "accepted", accepted_at: accepted_at)
  end

  def mark_as_converted!(converted_at: Time.current)
    raise ArgumentError, "採用済みの見積のみ注文へ変換できます" unless accepted?

    update!(status: "converted", converted_at: converted_at)
  end

  private

  def set_defaults
    self.quotation_date ||= Date.current
    self.expiration_date ||= quotation_date ? quotation_date + 30 : Date.current + 30
    self.status ||= "draft"
  end

  def tenant_consistency
    return if tenant_id.blank? || customer.blank?

    errors.add(:tenant, "と取引先の所属が一致しません") if tenant_id != customer.tenant_id
  end
end
