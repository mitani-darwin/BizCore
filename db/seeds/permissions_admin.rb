module Seeds
  class PermissionsAdmin
    RESOURCES = {
      dashboard: %w[index],
      tenants: %w[index show new create edit update destroy],
      users: %w[index show new create edit update destroy],
      roles: %w[index show new create edit update destroy],
      permissions: %w[index create update destroy],
      authorizations: %w[show update],
      assignments: %w[index create destroy],
      audit_logs: %w[index show]
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

      puts "PermissionsAdminSeeder: created=#{created_count}, updated=#{updated_count}, total=#{keys.size}"

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
            action: action,
            name: name_for(resource, action),
            description: description_for(resource, action),
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

    def description_for(resource, action)
      "権限キー: admin.#{resource}.#{action}"
    end

    def label_for(resource)
      {
        dashboard: "ダッシュボード",
        tenants: "テナント",
        users: "ユーザー",
        roles: "ロール",
        permissions: "権限定義",
        authorizations: "権限割当",
        assignments: "ロール付与"
      }.fetch(resource.to_sym, resource.to_s.humanize)
    end

    def action_label(action)
      {
        "index" => "一覧",
        "show" => "詳細表示",
        "new" => "新規画面",
        "create" => "作成",
        "edit" => "編集画面",
        "update" => "更新",
        "destroy" => "削除"
      }.fetch(action.to_s, action.to_s.humanize)
    end
  end
end
