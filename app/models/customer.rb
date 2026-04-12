class Customer < ApplicationRecord
  STATUSES = {
    active: "active",
    inactive: "inactive"
  }.freeze

  belongs_to :tenant

  has_many :quotations, dependent: :restrict_with_exception
  has_many :orders, dependent: :restrict_with_exception
  has_many :deliveries, dependent: :restrict_with_exception
  has_many :invoices, dependent: :restrict_with_exception
  has_many :payments, dependent: :restrict_with_exception

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
    [postal_code, address1, address2].compact_blank.join(" ")
  end

  def primary_contact
    [contact_person_department, contact_person_name].compact_blank.join(" ")
  end

  def outstanding_invoice_amount
    open_invoices_sum(:balance_amount)
  end

  def unpaid_invoice_count
    open_invoices_scope.size
  end

  def overdue_invoice_amount(as_of: Date.current)
    sum_decimal(overdue_invoices(as_of: as_of), :balance_amount)
  end

  def overdue_invoice_count(as_of: Date.current)
    overdue_invoices(as_of: as_of).size
  end

  def receivable_aging(as_of: Date.current)
    open_invoices_scope.each_with_object(default_aging_hash) do |invoice, aging|
      balance = invoice.balance_amount.to_d
      next if balance <= 0

      bucket = aging_bucket_for(invoice.due_date, as_of)
      aging[bucket] += balance
    end
  end

  def total_billed_amount
    invoice_records = association(:invoices).loaded? ? invoices.reject(&:cancelled?) : invoices.where.not(status: "cancelled")
    sum_decimal(invoice_records, :total_amount)
  end

  def total_payment_amount
    payment_records = association(:payments).loaded? ? payments.reject(&:cancelled?) : payments.where.not(status: "cancelled")
    sum_decimal(payment_records, :amount)
  end

  def last_order_date
    association(:orders).loaded? ? orders.map(&:order_date).compact.max : orders.maximum(:order_date)
  end

  def last_invoice_date
    association(:invoices).loaded? ? invoices.map(&:invoice_date).compact.max : invoices.maximum(:invoice_date)
  end

  def last_payment_date
    association(:payments).loaded? ? payments.map(&:payment_date).compact.max : payments.maximum(:payment_date)
  end

  def billing_closes_on?(date)
    return true if closing_day.blank?

    date.day == effective_closing_day_for(date)
  end

  def effective_closing_day_for(date)
    configured_day = closing_day.to_i
    return date.end_of_month.day if configured_day <= 0

    [configured_day, date.end_of_month.day].min
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

  def open_invoices_scope
    if association(:invoices).loaded?
      invoices.select { |invoice| %w[issued partially_paid].include?(invoice.status) && invoice.balance_amount.to_d.positive? }
    else
      invoices.where(status: %w[issued partially_paid]).where("balance_amount > 0")
    end
  end

  def overdue_invoices(as_of:)
    open_invoices_scope.select { |invoice| invoice.due_date.present? && invoice.due_date < as_of }
  end

  def open_invoices_sum(attribute)
    sum_decimal(open_invoices_scope, attribute)
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
