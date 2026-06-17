module Tenants
  # テナント作成直後にデフォルトの組み込みロールと権限を設定するサービス。
  # オーナー・管理者・マネージャー・閲覧者の4ロールを作成し、
  # Permission レコードが存在する場合は適切な権限を割り当てる。
  class SetupDefaultRoles
    def self.call(tenant)
      new(tenant).call
    end

    def initialize(tenant)
      @tenant = tenant
    end

    def call
      all_ids    = Permission.where("key LIKE 'admin.%'").pluck(:id)
      read_ids   = Permission.where("key LIKE 'admin.%.read'").pluck(:id)
      mgr_ids    = Permission.where("key LIKE 'admin.users.%' OR key LIKE 'admin.roles.%'").pluck(:id)

      owner   = upsert_role(key: "owner",   name: "オーナー",       description: "全権限",                    built_in: true)
      admin   = upsert_role(key: "admin",   name: "管理者",         description: "全権限",                    built_in: true)
      manager = upsert_role(key: "manager", name: "マネージャー",   description: "閲覧 + ユーザ/ロール編集",  built_in: false)
      viewer  = upsert_role(key: "viewer",  name: "閲覧者",         description: "閲覧のみ",                  built_in: false)

      owner.permission_ids   = all_ids
      admin.permission_ids   = all_ids
      manager.permission_ids = (read_ids + mgr_ids).uniq
      viewer.permission_ids  = read_ids
    end

    private

    attr_reader :tenant

    def upsert_role(key:, name:, description:, built_in:)
      tenant.roles.find_or_create_by!(key: key) do |r|
        r.name        = name
        r.description = description
        r.built_in    = built_in
      end
    end
  end
end
