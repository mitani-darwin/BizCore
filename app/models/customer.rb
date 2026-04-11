class Customer < ApplicationRecord
  STATUSES = {
    active: "active",
    inactive: "inactive"
  }.freeze

  belongs_to :tenant

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

  private

  def set_defaults
    self.status ||= "active"
  end

  def open_invoices_scope
    if association(:invoices).loaded?
      invoices.select { |invoice| %w[issued partially_paid].include?(invoice.status) }
    else
      invoices.where(status: %w[issued partially_paid])
    end
  end

  def open_invoices_sum(attribute)
    sum_decimal(open_invoices_scope, attribute)
  end

  def sum_decimal(records, attribute)
    if records.respond_to?(:sum) && !records.is_a?(Array)
      records.sum(attribute).to_d
    else
      Array(records).sum { |record| record.public_send(attribute).to_d }
    end
  end
end
