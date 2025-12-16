class Assignment < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: [:tenant_id, :role_id] }
  validate :tenant_consistency

  before_validation :sync_tenant

  private

  def sync_tenant
    self.tenant_id ||= user&.tenant_id || role&.tenant_id
  end

  def tenant_consistency
    return if tenant_id.blank? || user.blank? || role.blank?

    if tenant_id != user.tenant_id || tenant_id != role.tenant_id
      errors.add(:tenant, "とユーザ/ロールの所属が一致しません")
    end
  end
end
