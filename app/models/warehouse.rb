class Warehouse < ApplicationRecord
  belongs_to :tenant

  has_many :stock_items, dependent: :restrict_with_exception
  has_many :stock_movements, dependent: :restrict_with_exception
  has_many :stock_counts, dependent: :restrict_with_exception
  has_many :stock_allocations, dependent: :restrict_with_exception
  has_many :purchase_orders, dependent: :restrict_with_exception
  has_many :purchase_receipts, dependent: :restrict_with_exception
  has_many :purchase_adjustments, dependent: :restrict_with_exception

  validates :code, :name, presence: true
  validates :code, uniqueness: { scope: :tenant_id }
end
