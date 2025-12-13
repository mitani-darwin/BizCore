# frozen_string_literal: true

# Default data bootstrap for development/testing.
# Idempotent: running seeds multiple times will not duplicate records.

DEFAULT_ADMIN_EMAIL = "mitani@darwin-chiba.jp"
DEFAULT_ADMIN_PASSWORD = ENV.fetch("DEFAULT_ADMIN_PASSWORD", "ChangeMe123!")

def ensure_tenant(attrs)
  Tenant.find_or_create_by!(code: attrs.fetch(:code)) do |t|
    t.name = attrs.fetch(:name)
    t.subdomain = attrs.fetch(:subdomain)
    t.plan = attrs[:plan] || "standard"
    t.status = attrs[:status] || "active"
    t.billing_email = attrs[:billing_email] || DEFAULT_ADMIN_EMAIL
  end
end

def ensure_roles_for(tenant)
  base = {
    "owner" => { name: "オーナー", built_in: true, description: "全権限" },
    "admin" => { name: "管理者", built_in: true, description: "管理機能全般" },
    "manager" => { name: "マネージャー", description: "日常運用" },
    "viewer" => { name: "閲覧者", description: "閲覧のみ" },
    "finance" => { name: "経理担当", description: "請求・支払確認" },
    "ops" => { name: "オペレーション", description: "日常オペレーション" },
    "support" => { name: "サポート", description: "サポート窓口" },
    "sales" => { name: "営業", description: "営業閲覧" },
    "product" => { name: "プロダクト", description: "設定変更" },
    "qa" => { name: "QA", description: "検証用" }
  }

  base.each_with_object({}) do |(key, attrs), memo|
    memo[key] = tenant.roles.find_or_create_by!(key: key) do |role|
      role.name = attrs[:name]
      role.description = attrs[:description]
      role.built_in = attrs[:built_in] || false
    end
  end
end

def ensure_user(tenant:, email:, name:, roles: [], owner: false)
  user = User.find_or_initialize_by(email: email)
  user.tenant = tenant
  user.name = name
  user.is_owner = owner
  user.password = DEFAULT_ADMIN_PASSWORD
  user.password_confirmation = DEFAULT_ADMIN_PASSWORD
  user.role_ids = roles.map(&:id) if roles.any?
  user.save!

  user
end

base_tenants = [
  { code: "darwin", name: "Darwin HQ", subdomain: "darwin", plan: "enterprise", status: "active", billing_email: DEFAULT_ADMIN_EMAIL },
  { code: "acme", name: "Acme Corp", subdomain: "acme", plan: "standard", status: "active", billing_email: "ops@acme.test" },
  { code: "globex", name: "Globex", subdomain: "globex", plan: "pro", status: "active", billing_email: "it@globex.test" }
]

# Fill up to 10 tenants total with generated data
(4..10).each do |idx|
  code = "tenant#{idx.to_s.rjust(2, '0')}"
  base_tenants << {
    code: code,
    name: "Tenant #{idx}",
    subdomain: "tenant#{idx}",
    plan: %w[standard pro enterprise].sample,
    status: "active",
    billing_email: "owner@#{code}.test"
  }
end

base_tenants.first[:billing_email] = DEFAULT_ADMIN_EMAIL # ensure mitani email stays

base_tenants.each do |attrs|
  tenant = ensure_tenant(attrs)
  roles = ensure_roles_for(tenant)

  # Owner
  ensure_user(
    tenant: tenant,
    email: attrs[:billing_email],
    name: "#{attrs[:name]} Owner",
    roles: [roles["owner"]],
    owner: true
  )

  # Create additional users up to 10 per tenant
  users_needed = 10
  (0...users_needed).each do |i|
    email = "#{tenant.code}.user#{i}@example.com"
    name = "#{tenant.name} User #{i + 1}"
    assigned_roles =
      case i
      when 0 then [roles["admin"]]
      when 1 then [roles["manager"]]
      when 2 then [roles["viewer"]]
      else
        roles.values.sample(2)
      end

    ensure_user(
      tenant: tenant,
      email: email,
      name: name,
      roles: assigned_roles,
      owner: false
    )
  end
end

puts "Seeded 10 tenants with 10 roles & 10 users each. Default password: #{DEFAULT_ADMIN_PASSWORD}"
