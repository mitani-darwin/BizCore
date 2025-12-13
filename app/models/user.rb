class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  belongs_to :tenant

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions
  has_many :tenant_user_roles, foreign_key: :tenant_user_id, dependent: :destroy
  has_many :roles_via_tenant_user_roles, through: :tenant_user_roles, source: :role

  validates :tenant, presence: { message: "を選択してください" }
  validates :name, presence: { message: "を入力してください" }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :roles_must_be_selected

  def can?(permission_key)
    permissions.exists?(key: permission_key)
  end

  private

  def self.human_attribute_name(attr, options = {})
    return "ロール" if attr.to_s == "roles"
    return "氏名" if attr.to_s == "name"

    super
  end

  def roles_must_be_selected
    return if is_owner?
    return if roles.any? || role_ids.reject(&:blank?).any?

    errors.add(:roles, "を選択してください")
  end
end
