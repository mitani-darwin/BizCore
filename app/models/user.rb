# 管理画面にログインするユーザーを表すモデル。
# Devise で認証を管理し、ロール経由で権限を持つ。
# is_owner? フラグが true のユーザーはすべての権限を通す特権ユーザー。
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  belongs_to :tenant
  belongs_to :employee, optional: true

  has_many :assignments, dependent: :destroy
  has_many :roles, through: :assignments
  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions
  has_many :executed_billing_batches, class_name: "BillingBatch", foreign_key: :executed_by_id, dependent: :nullify, inverse_of: :executed_by
  has_many :cancelled_billing_batches, class_name: "BillingBatch", foreign_key: :cancelled_by_id, dependent: :nullify, inverse_of: :cancelled_by

  validates :tenant, presence: { message: "を選択してください" }
  validates :name, presence: { message: "を入力してください" }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :roles_must_be_selected
  validate :employee_must_belong_to_same_tenant

  # 指定の権限キーを持つかどうかを返す。owner は常に true。
  def can?(permission_key)
    Ability.new(self).can?(permission_key)
  end

  # 指定テナントにおけるユーザーの権限一覧を返す。
  # テナント不一致の場合は空リストを返し、クロステナントアクセスを防ぐ。
  def permissions_for(tenant)
    return Permission.none if tenant.blank?
    return Permission.none if tenant_id.present? && tenant_id != tenant.id

    roles_for_tenant = roles.joins(:assignments).where(assignments: { tenant_id: tenant.id })
    Permission.joins(role_permissions: :role)
              .where(roles: { id: roles_for_tenant.select(:id) })
              .distinct
  end

  private

  def self.human_attribute_name(attr, options = {})
    return "ロール" if attr.to_s == "roles"
    return "氏名" if attr.to_s == "name"

    super
  end

  def roles_must_be_selected
    return if is_owner?
    return if employee.present?
    return if roles.any? || role_ids.reject(&:blank?).any?

    errors.add(:roles, "を選択してください")
  end

  def employee_must_belong_to_same_tenant
    return if employee.blank? || tenant_id.blank?

    errors.add(:employee, "は同じテナントの従業員を選択してください") if employee.tenant_id != tenant_id
  end
end
