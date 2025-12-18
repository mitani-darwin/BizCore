require "test_helper"

class AuthorizationTest < ActiveSupport::TestCase
  class DummyActor
    def initialize(permissions)
      @permissions = permissions
    end

    def permissions_for(_tenant)
      @permissions
    end
  end

  setup do
    @tenant = Tenant.create!(
      name: "Auth Tenant",
      code: "auth-tenant",
      subdomain: "auth",
      plan: "standard",
      status: "active",
      billing_email: "auth@example.com"
    )

    @permission = Permission.create!(
      key: "admin.tenants.read",
      resource: "tenants",
      action: "read",
      name: "テナント閲覧",
      description: "テナントを閲覧できる"
    )
  end

  test "can? returns true when actor has permission" do
    actor = DummyActor.new([@permission])

    assert Authorization.can?(actor: actor, tenant: @tenant, key: @permission.key)
  end

  test "can? returns false when actor lacks permission" do
    actor = DummyActor.new([])

    assert_not Authorization.can?(actor: actor, tenant: @tenant, key: @permission.key)
  end

  test "authorize! raises AuthorizationError when not allowed" do
    actor = DummyActor.new([])

    assert_raises(AuthorizationError) do
      Authorization.authorize!(actor: actor, tenant: @tenant, key: @permission.key)
    end
  end
end
