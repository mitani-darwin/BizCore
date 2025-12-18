require_relative "seeds/permissions/admin_permissions"

# 実行順序: permissions -> roles -> users(assignments)
DEFAULT_PASSWORD = ENV.fetch("DEFAULT_PASSWORD", "ChangeMe123!")

def ensure_tenant(attrs)
  Tenant.find_or_create_by!(code: attrs.fetch(:code)) do |t|
    t.name = attrs.fetch(:name)
    t.subdomain = attrs.fetch(:subdomain)
    t.plan = attrs[:plan] || "standard"
    t.status = attrs[:status] || "active"
    t.billing_email = attrs[:billing_email] || "owner@#{attrs[:code]}.example.com"
  end
end

def ensure_roles(tenant, permission_records)
  all_ids = permission_records.values.map(&:id)
  read_ids = permission_records.values.select { |p| p.action == "read" }.map(&:id)

  owner = tenant.roles.find_or_create_by!(key: "owner") do |r|
    r.name = "オーナー"
    r.description = "全権限"
    r.built_in = true
  end
  admin = tenant.roles.find_or_create_by!(key: "admin") do |r|
    r.name = "管理者"
    r.description = "全権限"
    r.built_in = true
  end
  manager = tenant.roles.find_or_create_by!(key: "manager") do |r|
    r.name = "マネージャー"
    r.description = "閲覧 + ユーザ/ロール編集"
    r.built_in = false
  end
  viewer = tenant.roles.find_or_create_by!(key: "viewer") do |r|
    r.name = "閲覧者"
    r.description = "閲覧のみ"
    r.built_in = false
  end

  owner.permission_ids = all_ids
  admin.permission_ids = all_ids
  manager.permission_ids = (read_ids + permission_records.values.select { |p| %w[users roles].include?(p.resource) }.map(&:id)).uniq
  viewer.permission_ids = read_ids

  { owner: owner, admin: admin, manager: manager, viewer: viewer }
end

def ensure_user(tenant:, email:, name:, roles: [], owner_flag: false)
  user = User.find_or_initialize_by(email: email)
  user.tenant = tenant
  user.name = name
  user.is_owner = owner_flag
  user.password = DEFAULT_PASSWORD
  user.password_confirmation = DEFAULT_PASSWORD
  user.locale = "ja"
  user.time_zone = "Asia/Tokyo"
  user.role_ids = roles.map(&:id) if roles.present?
  user.save!

  roles.each do |role|
    Assignment.find_or_create_by!(tenant:, user:, role:)
  end

  user
end

permissions = Seeds::Permissions::Admin.call

tenants = [
  { code: "darwin", name: "Darwin HQ", subdomain: "darwin", plan: "enterprise", billing_email: "owner@darwin.example.com" },
  { code: "acme", name: "Acme Corp", subdomain: "acme", plan: "standard", billing_email: "owner@acme.example.com" }
]

tenants.each do |attrs|
  tenant = ensure_tenant(attrs)
  roles = ensure_roles(tenant, permissions)

  owner_user = ensure_user(
    tenant: tenant,
    email: attrs[:billing_email],
    name: "#{attrs[:name]} オーナー",
    roles: [roles[:owner]],
    owner_flag: true
  )

  ensure_user(
    tenant: tenant,
    email: "admin@#{tenant.code}.example.com",
    name: "#{tenant.name} 管理者",
    roles: [roles[:admin]],
    owner_flag: false
  )

  ensure_user(
    tenant: tenant,
    email: "manager@#{tenant.code}.example.com",
    name: "#{tenant.name} マネージャー",
    roles: [roles[:manager]],
    owner_flag: false
  )

  ensure_user(
    tenant: tenant,
    email: "viewer@#{tenant.code}.example.com",
    name: "#{tenant.name} 閲覧者",
    roles: [roles[:viewer]],
    owner_flag: false
  )
end

puts "Seeded tenants, roles, permissions, and sample users. Default password: #{DEFAULT_PASSWORD}"
