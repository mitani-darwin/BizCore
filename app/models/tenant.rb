class Tenant < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy

  validates :name, :code, :subdomain, :plan, :status, :billing_email, presence: true
  validates :code, :subdomain, uniqueness: true
  validates :billing_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # 仮想属性: 画面用に補完する値
  attribute :primary_domain, :string
  attribute :started_on, :date
  attribute :last_access_at, :datetime

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
end
