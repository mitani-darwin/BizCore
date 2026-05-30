# 商談（営業案件）を表すモデル。hearing → proposal → negotiation → won/lost のステージで進捗を管理する。
# 受注確度（probability）を掛けた加重期待金額（weighted_expected_amount）でパイプライン集計ができる。
class CustomerOpportunity < ApplicationRecord
  include DocumentNumbering

  STAGES = {
    hearing: "hearing",
    proposal: "proposal",
    negotiation: "negotiation",
    won: "won",
    lost: "lost"
  }.freeze

  belongs_to :tenant
  belongs_to :customer
  belongs_to :customer_inquiry, optional: true
  belongs_to :assigned_user, class_name: "User", optional: true

  enum :stage, STAGES

  generates_document_number :opportunity_number, prefix: "OPP"

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    left_outer_joins(:customer).where(
      <<~SQL.squish,
        customer_opportunities.opportunity_number LIKE :pattern OR
        customer_opportunities.subject LIKE :pattern OR
        customer_opportunities.summary LIKE :pattern OR
        customer_opportunities.next_action LIKE :pattern OR
        customers.name LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_stage, ->(stage) { stage.present? ? where(stage: stage) : all }
  scope :with_customer, ->(customer_id) { customer_id.present? ? where(customer_id: customer_id) : all }
  scope :ordered_for_admin, -> { order(opened_on: :desc, id: :desc) }

  validates :opportunity_number, :opened_on, :stage, :subject, presence: true
  validates :expected_amount, :actual_sales_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :probability, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :apply_inquiry_defaults
  before_validation :normalize_closed_values

  def open?
    !won? && !lost?
  end

  def weighted_expected_amount
    expected_amount.to_d * probability.to_i / 100
  end

  private

  def set_defaults
    self.opened_on ||= Date.current
    self.stage ||= "hearing"
    self.expected_amount ||= 0
    self.actual_sales_amount ||= 0
    self.probability ||= 0
  end

  def apply_inquiry_defaults
    return unless customer_inquiry

    self.customer ||= customer_inquiry.customer
    self.subject = customer_inquiry.subject if subject.blank?
    self.summary = customer_inquiry.details if summary.blank?
    self.assigned_user ||= customer_inquiry.assigned_user
  end

  def normalize_closed_values
    return unless won? || lost?

    self.closed_on ||= expected_close_on || Date.current
    self.actual_sales_amount = expected_amount if won? && actual_sales_amount.to_d.zero? && expected_amount.to_d.positive?
  end

  def tenant_consistency
    return if tenant_id.blank? || customer.blank?

    mismatch = tenant_id != customer.tenant_id
    mismatch ||= customer_inquiry.present? && tenant_id != customer_inquiry.tenant_id
    mismatch ||= customer_inquiry.present? && customer_inquiry.customer_id.present? && customer_id != customer_inquiry.customer_id
    mismatch ||= assigned_user.present? && tenant_id != assigned_user.tenant_id
    errors.add(:tenant, "と商談先の所属が一致しません") if mismatch
  end
end
