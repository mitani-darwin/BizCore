class AuditLogger
  SENSITIVE_KEYS = %w[
    encrypted_password
    password
    password_confirmation
    reset_password_token
    reset_password_sent_at
  ].freeze

  def self.log(tenant:, user:, action:, auditable:, request:)
    return unless auditable.is_a?(ActiveRecord::Base)

    AuditLog.create!(
      tenant: tenant,
      user: user,
      action: action,
      auditable_type: auditable.class.name,
      auditable_id: auditable.id,
      summary: summary_for(action, auditable),
      changes: changes_for(action, auditable),
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def self.summary_for(action, record)
    "#{record.model_name.human}を#{action_label(action)}"
  end

  def self.action_label(action)
    {
      "create" => "作成",
      "update" => "更新",
      "destroy" => "削除"
    }.fetch(action.to_s, action.to_s)
  end

  def self.changes_for(action, record)
    return nil unless action.to_s == "update"
    return nil unless record.respond_to?(:saved_changes)

    filtered = record.saved_changes.except(*SENSITIVE_KEYS)
    return nil if filtered.empty?

    filtered.to_h
  end
end
