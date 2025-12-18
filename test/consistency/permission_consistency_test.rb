require "test_helper"

class PermissionConsistencyTest < ActionDispatch::IntegrationTest
  ROUTE_ACTION_MAP = {
    "index" => "read",
    "show" => "read",
    "new" => "create",
    "create" => "create",
    "edit" => "update",
    "update" => "update",
    "destroy" => "delete"
  }.freeze

  setup do
    AuditLog.delete_all
    RolePermission.delete_all if defined?(RolePermission)
    UserRole.delete_all if defined?(UserRole)
    TenantUserRole.delete_all if defined?(TenantUserRole)
    Assignment.delete_all
    Role.delete_all
    User.delete_all
    Tenant.delete_all
    Permission.delete_all

    Permissions::Catalog.seed_admin!
  end

  test "admin routes map to existing permission keys" do
    missing = admin_routes.filter_map do |route|
      mapped_action = ROUTE_ACTION_MAP[route[:action]]
      next if mapped_action.nil?

      key = Permissions::Catalog.admin_key(route[:resource], mapped_action)
      key unless Permission.exists?(key: key)
    end

    assert missing.empty?, "Missing permission keys: #{missing.uniq.sort.join(', ')}"
  end

  test "navigation required_keys exist in permissions" do
    missing = navigation_keys.reject { |key| Permission.exists?(key: key) }

    assert missing.empty?, "Missing navigation permission keys: #{missing.uniq.sort.join(', ')}"
  end

  test "audit log action_key matches permission key" do
    tenant = Tenant.create!(
      name: "Audit Tenant",
      code: "audit-tenant",
      subdomain: "audit",
      plan: "standard",
      status: "active",
      billing_email: "audit@example.com"
    )

    User.create!(
      tenant: tenant,
      name: "Owner User",
      email: "owner@audit.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    assert_difference("AuditLog.count", 1) do
      patch admin_tenant_path(tenant), params: { tenant: { name: "Updated Tenant" } }
    end

    audit_log = AuditLog.order(created_at: :desc).first
    assert_equal Permissions::Catalog.admin_key(:tenants, :update), audit_log.action_key
    assert_equal tenant.id, audit_log.tenant_id
  end

  private

  def admin_routes
    Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank?
      next unless controller.start_with?("admin/")
      next if controller.start_with?("admin/rails") || controller.start_with?("admin/active_storage")

      resource = controller.split("/").last
      { controller: controller, action: action, resource: resource }
    end
  end

  def navigation_keys
    sections = Admin::Navigation.sections
    items = sections.flat_map(&:items)
    keys = items.flat_map { |item| collect_keys(item) }
    keys.uniq
  end

  def collect_keys(item)
    keys = Array(item.required_keys)
    child_keys = item.children.flat_map { |child| collect_keys(child) }
    keys + child_keys
  end
end
