# ユーザー操作の監査ログを記録するモデル。
# actor（操作者）と auditable（操作対象）は多態関連で様々なモデルに紐づく。
# succeeded / failed / denied の 3 種類のステータスで結果を記録する。
class AuditLog < ApplicationRecord
  STATUSES = {
    succeeded: "succeeded",
    failed: "failed",
    denied: "denied"
  }.freeze

  belongs_to :tenant
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  attribute :metadata, :json, default: {}

  validates :tenant_id, :action_key, :status, presence: true
  validates :status, inclusion: { in: STATUSES.values }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_tenant, ->(tenant) { where(tenant_id: tenant.respond_to?(:id) ? tenant.id : tenant) }
end
