class CustomerInquiry < ApplicationRecord
  include DocumentNumbering

  STATUSES = {
    new: "new",
    responding: "responding",
    qualified: "qualified",
    closed: "closed"
  }.freeze

  SOURCES = {
    web: "web",
    phone: "phone",
    email: "email",
    visit: "visit",
    referral: "referral",
    other: "other"
  }.freeze

  belongs_to :tenant
  belongs_to :customer, optional: true
  belongs_to :assigned_user, class_name: "User", optional: true

  has_many :customer_opportunities, dependent: :nullify

  enum :status, STATUSES, prefix: true
  enum :source, SOURCES

  generates_document_number :inquiry_number, prefix: "INQ"

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    left_outer_joins(:customer).where(
      <<~SQL.squish,
        customer_inquiries.inquiry_number LIKE :pattern OR
        customer_inquiries.subject LIKE :pattern OR
        customer_inquiries.company_name LIKE :pattern OR
        customer_inquiries.contact_person_name LIKE :pattern OR
        customer_inquiries.contact_email LIKE :pattern OR
        customers.name LIKE :pattern
      SQL
      pattern: pattern
    )
  }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :with_source, ->(source) { source.present? ? where(source: source) : all }
  scope :with_customer, ->(customer_id) { customer_id.present? ? where(customer_id: customer_id) : all }
  scope :ordered_for_admin, -> { order(inquiry_date: :desc, id: :desc) }

  validates :inquiry_number, :inquiry_date, :status, :source, :subject, presence: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :company_name, presence: true, unless: :customer_id?
  validate :tenant_consistency

  before_validation :set_defaults
  before_validation :apply_customer_defaults

  def company_label
    customer&.name.presence || company_name.presence || "-"
  end

  def primary_contact
    [contact_person_department, contact_person_name].compact_blank.join(" ")
  end

  def open?
    !status_closed?
  end

  private

  def set_defaults
    self.inquiry_date ||= Date.current
    self.status ||= "new"
    self.source ||= "email"
  end

  def apply_customer_defaults
    return unless customer

    self.company_name = customer.name if company_name.blank?
    self.contact_person_name = customer.contact_person_name if contact_person_name.blank?
    self.contact_person_department = customer.contact_person_department if contact_person_department.blank?
    self.contact_email = customer.contact_person_email.presence || customer.email if contact_email.blank?
    self.contact_tel = customer.contact_person_tel.presence || customer.tel if contact_tel.blank?
  end

  def tenant_consistency
    return if tenant_id.blank?

    mismatch = customer.present? && tenant_id != customer.tenant_id
    mismatch ||= assigned_user.present? && tenant_id != assigned_user.tenant_id
    errors.add(:tenant, "と問い合わせ先の所属が一致しません") if mismatch
  end
end
