class Customer < ApplicationRecord
  belongs_to :tenant

  has_many :orders, dependent: :restrict_with_exception
  has_many :deliveries, dependent: :restrict_with_exception
  has_many :invoices, dependent: :restrict_with_exception
  has_many :payments, dependent: :restrict_with_exception

  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :tenant_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def full_address
    [postal_code, address1, address2].compact_blank.join(" ")
  end
end
