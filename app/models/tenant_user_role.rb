class TenantUserRole < ApplicationRecord
  belongs_to :tenant_user, class_name: "User", foreign_key: :tenant_user_id
  belongs_to :role

  validates :tenant_user_id, uniqueness: { scope: :role_id }
end
