require "securerandom"

class User < ApplicationRecord
  belongs_to :tenant

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions
  has_many :tenant_user_roles, foreign_key: :tenant_user_id, dependent: :destroy
  has_many :roles_via_tenant_user_roles, through: :tenant_user_roles, source: :role

  has_secure_password validations: false

  validates :tenant, presence: { message: "を選択してください" }
  validates :name, presence: { message: "を入力してください" }
  validates :email, uniqueness: { scope: :tenant_id }, allow_blank: true
  validate :email_or_line_id_present
  validates :password, presence: true, length: { minimum: 6 }, unless: :initial_flag?
  validate :roles_must_be_selected

  before_validation :set_placeholder_password, if: :initial_flag?

  def can?(permission_key)
    permissions.exists?(key: permission_key)
  end

  private

  def self.human_attribute_name(attr, options = {})
    return "ロール" if attr.to_s == "roles"
    return "氏名" if attr.to_s == "name"

    super
  end

  def email_or_line_id_present
    return if email.present? || line_id.present?

    errors.add(:base, "メールアドレスまたはLINE IDのいずれかを入力してください。")
  end

  def set_placeholder_password
    return if password.present? || password_digest.present?

    generated = SecureRandom.hex(12)
    self.password = generated
    self.password_confirmation = generated
  end

  def roles_must_be_selected
    return if roles.any? || role_ids.reject(&:blank?).any?

    errors.add(:roles, "を選択してください")
  end
end
