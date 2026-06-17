require "test_helper"

class Admin::AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Assignment Tenant",
      code: "assign-test",
      subdomain: "assign-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@assign-test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Assignment Owner",
      email: "owner@assign-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @role = @tenant.roles.create!(
      name: "一般スタッフ",
      key: "staff",
      built_in: false
    )

    # roles_must_be_selected バリデーションを通すために最低1ロールを付与して作成
    @target_user = User.create!(
      tenant: @tenant,
      name: "テストユーザー",
      email: "staff@assign-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: false,
      role_ids: [ @role.id ]
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "index が成功する" do
    get admin_assignments_path
    assert_response :success
    assert_select "h1", text: "ロール付与"
  end

  test "index にユーザーとロールが表示される" do
    get admin_assignments_path
    assert_response :success
    assert_select "td", text: /テストユーザー/
    assert_select "th", text: /一般スタッフ/
  end

  test "create で新しいロールを追加できる" do
    new_role = @tenant.roles.create!(name: "追加ロール", key: "extra-role", built_in: false)

    assert_difference("Assignment.count", 1) do
      post admin_assignments_path, params: {
        assignments: { @target_user.id.to_s => [ @role.id.to_s, new_role.id.to_s ] }
      }
    end

    assert_redirected_to admin_assignments_path
    assert Assignment.exists?(user: @target_user, role: new_role, tenant: @tenant)
  end

  test "create でチェックを外すとロールが解除される" do
    # @target_user は @role を持っている状態からスタート
    assert_difference("Assignment.count", -1) do
      post admin_assignments_path, params: { assignments: {} }
    end

    assert_redirected_to admin_assignments_path
    assert_not Assignment.exists?(user: @target_user, role: @role)
  end

  test "他テナントのロールは付与できない" do
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-assign",
      subdomain: "other-assign",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-assign.example.com"
    )
    other_role = other_tenant.roles.create!(name: "他ロール", key: "other_staff", built_in: false)

    post admin_assignments_path, params: {
      assignments: { @target_user.id.to_s => [ other_role.id.to_s ] }
    }

    # 他テナントのロールは allowed_role_ids に含まれないため付与されない
    assert_not Assignment.exists?(role: other_role)
  end
end
