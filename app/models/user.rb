class User < ApplicationRecord
  belongs_to :tenant

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions
  has_many :tenant_user_roles, foreign_key: :tenant_user_id, dependent: :destroy
  has_many :roles_via_tenant_user_roles, through: :tenant_user_roles, source: :role

  has_secure_password

  validates :name, :email, presence: true
  validates :email, uniqueness: { scope: :tenant_id }

  def can?(permission_key)
    permissions.exists?(key: permission_key)
  end
end
