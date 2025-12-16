class AuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :user, optional: true

  validates :action, :auditable_type, :auditable_id, :summary, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_tenant, ->(tenant) { where(tenant:) }
end
