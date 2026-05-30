# 商品マスタを表すモデル。在庫・発注・受注・納品の各明細から参照される。
class Product < ApplicationRecord
  belongs_to :tenant

  has_many :stock_items, dependent: :restrict_with_exception
  has_many :stock_movements, dependent: :restrict_with_exception
  has_many :stock_counts, dependent: :restrict_with_exception
  has_many :stock_allocations, dependent: :restrict_with_exception
  has_many :purchase_order_items, dependent: :restrict_with_exception
  has_many :purchase_receipt_items, dependent: :restrict_with_exception
  has_many :purchase_adjustments, dependent: :restrict_with_exception
  has_many :quotation_items, dependent: :restrict_with_exception
  has_many :order_items, dependent: :restrict_with_exception
  has_many :delivery_items, dependent: :restrict_with_exception

  validates :code, :name, :unit_name, presence: true
  validates :code, uniqueness: { scope: :tenant_id }
  validates :standard_price, numericality: { greater_than_or_equal_to: 0 }
end
