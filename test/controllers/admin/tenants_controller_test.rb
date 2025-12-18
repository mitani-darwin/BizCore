require "test_helper"

class Admin::TenantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Test Tenant",
      code: "test-tenant",
      subdomain: "test",
      plan: "standard",
      status: "active",
      billing_email: "owner@test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Owner User",
      email: "owner@test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    Permission.create!(
      key: "admin.tenants.update",
      resource: "tenants",
      action: "update",
      name: "テナント更新",
      description: "テナントを更新できる"
    )
  end

  test "update writes an audit log" do
    assert_difference("AuditLog.count", 1) do
      patch admin_tenant_path(@tenant), params: { tenant: { name: "Updated Tenant" } }
    end

    audit_log = AuditLog.order(created_at: :desc).first
    assert_equal "admin.tenants.update", audit_log.action_key
    assert_equal @tenant.id, audit_log.tenant_id
    assert_equal @tenant.id, audit_log.auditable_id
    assert_equal "Tenant", audit_log.auditable_type
    assert_equal "succeeded", audit_log.status
  end
end
