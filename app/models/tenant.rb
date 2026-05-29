class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :customer_inquiries, dependent: :destroy
  has_many :customer_opportunities, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :work_shifts, dependent: :destroy
  has_many :attendance_records, dependent: :destroy
  has_many :leave_requests, dependent: :destroy
  has_many :payroll_runs, dependent: :destroy
  has_many :payroll_entries, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  has_many :stock_items, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :stock_counts, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :purchase_receipts, dependent: :destroy
  has_many :purchase_adjustments, dependent: :destroy
  has_many :purchase_bill_batches, dependent: :destroy
  has_many :purchase_bills, dependent: :destroy
  has_many :supplier_payments, dependent: :destroy
  has_many :quotations, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :billing_batches, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :document_templates, dependent: :destroy
  has_many :sites, dependent: :destroy
  has_many :daily_reports, dependent: :destroy
  has_many :expense_reports, dependent: :destroy

  validates :name, :code, :subdomain, :plan, :status, :billing_email, presence: true
  validates :code, :subdomain, uniqueness: true
  validates :billing_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :billing_closing_day, :payroll_closing_day, :purchase_closing_day,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 31 },
            allow_nil: true

  # 仮想属性: 画面用に補完する値
  attribute :primary_domain, :string
  attribute :started_on, :date
  attribute :last_access_at, :datetime

  after_create :create_default_admin_role

  def primary_domain
    value = read_attribute(:primary_domain)
    return value if value.present?

    subdomain.present? ? "#{subdomain}.example.com" : nil
  end

  def started_on
    read_attribute(:started_on) || created_at&.to_date
  end

  def last_access_at
    read_attribute(:last_access_at) || updated_at
  end

  def effective_billing_closing_day_for(date)
    closing_day_for(billing_closing_day, date)
  end

  def effective_payroll_closing_day_for(date)
    closing_day_for(payroll_closing_day, date)
  end

  def effective_purchase_closing_day_for(date)
    closing_day_for(purchase_closing_day, date)
  end

  private

  def closing_day_for(configured_day, date)
    return date.end_of_month.day if configured_day.blank? || configured_day.to_i <= 0

    [ configured_day.to_i, date.end_of_month.day ].min
  end

  def create_default_admin_role
    roles.create!(
      name: "管理者",
      key: "admin",
      description: "管理者",
      built_in: true
    )
  end
end
