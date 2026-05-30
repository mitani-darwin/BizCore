# 画面・操作単位の権限定義。キー形式は "admin.<resource>.<action>"。
# Permissions::Catalog.seed_admin! によって一括 upsert される。
class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, :resource, :action, :name, presence: true
  validates :key, uniqueness: true
end
