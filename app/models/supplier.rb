class Supplier < ApplicationRecord
  STATUSES = {
    active: "active",
    inactive: "inactive"
  }.freeze

  belongs_to :tenant

  has_many :purchase_orders, dependent: :restrict_with_exception
  has_many :purchase_receipts, dependent: :restrict_with_exception
  has_many :purchase_adjustments, dependent: :restrict_with_exception

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

  private

  def set_defaults
    self.status ||= "active"
  end
end
