module Seeds
  module Permissions
    class Admin
      RESOURCES = {
        dashboard: %i[read],
        tenants: %i[read create update delete],
        users: %i[read create update delete],
        roles: %i[read create update delete],
        permissions: %i[read create update delete],
        authorizations: %i[read update],
        assignments: %i[read create delete],
        audit_logs: %i[read]
      }.freeze

      def self.call
        new.call
      end

      def call
        keys = build_rows.map { |row| row[:key] }
        existing_keys = Permission.where(key: keys).pluck(:key).to_set

        upsert_rows!

        created_count = keys.count { |k| !existing_keys.include?(k) }
        updated_count = existing_keys.size

        puts "AdminPermissionSeed: created=#{created_count}, updated=#{updated_count}, total=#{keys.size}"

        Permission.where(key: keys).index_by(&:key)
      end

      private

      def build_rows
        now = Time.current
        RESOURCES.flat_map do |resource, actions|
          actions.map do |action|
            key = "admin.#{resource}.#{action}"
            {
              key: key,
              resource: resource.to_s,
              action: action.to_s,
              name: name_for(resource, action),
              description: description_for(key),
              category: resource.to_s,
              created_at: now,
              updated_at: now
            }
          end
        end
      end

      def upsert_rows!
        Permission.upsert_all(
          build_rows,
          unique_by: :key,
          record_timestamps: false
        )
      end

      def name_for(resource, action)
        "#{label_for(resource)}: #{action_label(action)}"
      end

      def description_for(key)
        "権限キー: #{key}"
      end

      def label_for(resource)
        {
          dashboard: "ダッシュボード",
          tenants: "テナント",
          users: "ユーザー",
          roles: "ロール",
          permissions: "権限定義",
          authorizations: "権限割当",
          assignments: "ロール付与",
          audit_logs: "監査ログ"
        }.fetch(resource.to_sym, resource.to_s.humanize)
      end

      def action_label(action)
        {
          read: "閲覧",
          create: "作成",
          update: "更新",
          delete: "削除"
        }.fetch(action.to_sym, action.to_s.humanize)
      end
    end
  end
end
