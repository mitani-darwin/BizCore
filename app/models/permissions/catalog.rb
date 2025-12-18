module Permissions
  class Catalog
    ADMIN_RESOURCES = {
      dashboard: %i[read],
      tenants: %i[read create update delete],
      users: %i[read create update delete],
      roles: %i[read create update delete],
      permissions: %i[read create update delete],
      authorizations: %i[read update],
      assignments: %i[read create delete],
      audit_logs: %i[read]
    }.freeze

    RESOURCE_LABELS = {
      dashboard: "ダッシュボード",
      tenants: "テナント",
      users: "ユーザー",
      roles: "ロール",
      permissions: "権限定義",
      authorizations: "権限割当",
      assignments: "ロール付与",
      audit_logs: "監査ログ"
    }.freeze

    ACTION_LABELS = {
      read: "閲覧",
      create: "作成",
      update: "更新",
      delete: "削除"
    }.freeze

    def self.admin_entries
      now = Time.current
      ADMIN_RESOURCES.flat_map do |resource, actions|
        actions.map do |action|
          key = admin_key(resource, action)
          {
            key: key,
            resource: resource.to_s,
            action: action.to_s,
            name: "#{resource_label(resource)}: #{action_label(action)}",
            description: "権限キー: #{key}",
            category: resource.to_s,
            created_at: now,
            updated_at: now
          }
        end
      end
    end

    def self.admin_keys
      admin_entries.map { |entry| entry[:key] }
    end

    def self.admin_key(resource, action)
      "admin.#{resource}.#{action}"
    end

    def self.seed_admin!
      Permission.upsert_all(
        admin_entries,
        unique_by: :key,
        record_timestamps: false
      )
      Permission.where(key: admin_keys).index_by(&:key)
    end

    def self.resource_label(resource)
      RESOURCE_LABELS.fetch(resource.to_sym, resource.to_s.humanize)
    end

    def self.action_label(action)
      ACTION_LABELS.fetch(action.to_sym, action.to_s.humanize)
    end
  end
end
