# 仕入先を表すモデル。
# 買掛残高・エイジング分析の集計ロジックを持つ。Customer と対称的な設計。
class Supplier < ApplicationRecord
  STATUSES = {
    active: "active",
    inactive: "inactive"
  }.freeze

  belongs_to :tenant

  has_many :contracts, dependent: :restrict_with_exception
  has_many :purchase_orders, dependent: :restrict_with_exception
  has_many :purchase_receipts, dependent: :restrict_with_exception
  has_many :purchase_adjustments, dependent: :restrict_with_exception
  has_many :purchase_bills, dependent: :restrict_with_exception
  has_many :supplier_payments, dependent: :restrict_with_exception

  enum :status, STATUSES

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where(
      <<~SQL.squish,
        code LIKE :pattern OR
        name LIKE :pattern OR
        name_kana LIKE :pattern OR
        email LIKE :pattern OR
        contact_person_name LIKE :pattern OR
        contact_person_email LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :ordered_for_admin, -> { order(Arel.sql("CASE WHEN status = 'active' THEN 0 ELSE 1 END"), :code, :id) }

  validates :code, :name, :status, presence: true
  validates :code, uniqueness: { scope: :tenant_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :contact_person_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  before_validation :set_defaults

  def full_address
    [ postal_code, address1, address2 ].compact_blank.join(" ")
  end

  def primary_contact
    [ contact_person_department, contact_person_name ].compact_blank.join(" ")
  end

  def outstanding_purchase_bill_amount
    open_purchase_bills_sum(:balance_amount)
  end

  def unpaid_purchase_bill_count
    open_purchase_bills_scope.size
  end

  def overdue_purchase_bill_amount(as_of: Date.current)
    sum_decimal(overdue_purchase_bills(as_of: as_of), :balance_amount)
  end

  def overdue_purchase_bill_count(as_of: Date.current)
    overdue_purchase_bills(as_of: as_of).size
  end

  def payable_aging(as_of: Date.current)
    open_purchase_bills_scope.each_with_object(default_aging_hash) do |purchase_bill, aging|
      balance = purchase_bill.balance_amount.to_d
      next if balance <= 0

      bucket = aging_bucket_for(purchase_bill.due_date, as_of)
      aging[bucket] += balance
    end
  end

  def total_purchase_bill_amount
    purchase_bill_records =
      if association(:purchase_bills).loaded?
        purchase_bills.reject(&:cancelled?)
      else
        purchase_bills.where.not(status: "cancelled")
      end
    sum_decimal(purchase_bill_records, :total_amount)
  end

  def total_supplier_payment_amount
    payment_records =
      if association(:supplier_payments).loaded?
        supplier_payments.reject(&:cancelled?)
      else
        supplier_payments.where.not(status: "cancelled")
      end
    sum_decimal(payment_records, :amount)
  end

  def last_purchase_bill_date
    if association(:purchase_bills).loaded?
      purchase_bills.map(&:bill_date).compact.max
    else
      purchase_bills.maximum(:bill_date)
    end
  end

  def last_supplier_payment_date
    if association(:supplier_payments).loaded?
      supplier_payments.map(&:payment_date).compact.max
    else
      supplier_payments.maximum(:payment_date)
    end
  end

  def billing_closes_on?(date)
    return true if closing_day.blank?

    date.day == effective_closing_day_for(date)
  end

  def effective_closing_day_for(date)
    configured_day = closing_day.to_i
    return date.end_of_month.day if configured_day <= 0

    [ configured_day, date.end_of_month.day ].min
  end

  def due_date_for(closing_date:, default_due_date: nil)
    case payment_due_rule
    when "end_of_month"
      closing_date.end_of_month
    when "next_month_end"
      closing_date.next_month.end_of_month
    when "next_two_month_end"
      closing_date.next_month.next_month.end_of_month
    when "custom"
      default_due_date || closing_date.next_month.end_of_month
    else
      default_due_date || closing_date.next_month.end_of_month
    end
  end

  private

  def set_defaults
    self.status ||= "active"
  end

  def open_purchase_bills_scope
    if association(:purchase_bills).loaded?
      purchase_bills.select { |purchase_bill| %w[issued partially_paid].include?(purchase_bill.status) && purchase_bill.balance_amount.to_d.positive? }
    else
      purchase_bills.where(status: %w[issued partially_paid]).where("balance_amount > 0")
    end
  end

  def overdue_purchase_bills(as_of:)
    open_purchase_bills_scope.select { |purchase_bill| purchase_bill.due_date.present? && purchase_bill.due_date < as_of }
  end

  def open_purchase_bills_sum(attribute)
    sum_decimal(open_purchase_bills_scope, attribute)
  end

  def default_aging_hash
    {
      current: 0.to_d,
      overdue_1_30: 0.to_d,
      overdue_31_60: 0.to_d,
      overdue_61_over: 0.to_d
    }
  end

  def aging_bucket_for(due_date, as_of)
    return :current if due_date.blank?

    days_overdue = (as_of - due_date).to_i
    return :current if days_overdue <= 0
    return :overdue_1_30 if days_overdue <= 30
    return :overdue_31_60 if days_overdue <= 60

    :overdue_61_over
  end

  def sum_decimal(records, attribute)
    if records.respond_to?(:sum) && !records.is_a?(Array)
      records.sum(attribute).to_d
    else
      Array(records).sum { |record| record.public_send(attribute).to_d }
    end
  end
end
