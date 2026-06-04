require "test_helper"

class Admin::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Profile Tenant",
      code: "profile-tenant",
      subdomain: "profile",
      plan: "standard",
      status: "active",
      billing_email: "owner@profile.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Profile Owner",
      email: "owner@profile.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "edit_password を表示できる" do
    get edit_password_admin_profile_path
    assert_response :success
  end

  test "正しい現在のパスワードでパスワードを変更できる" do
    patch update_password_admin_profile_path, params: {
      user: {
        current_password: "Password123!",
        password: "NewPassword456!",
        password_confirmation: "NewPassword456!"
      }
    }

    assert_redirected_to edit_password_admin_profile_path
    assert_equal "パスワードを変更しました。", flash[:notice]
    assert @owner.reload.valid_password?("NewPassword456!")
  end

  test "現在のパスワードが間違っている場合は変更できない" do
    patch update_password_admin_profile_path, params: {
      user: {
        current_password: "WrongPassword!",
        password: "NewPassword456!",
        password_confirmation: "NewPassword456!"
      }
    }

    assert_response :unprocessable_entity
    assert @owner.reload.valid_password?("Password123!")
  end

  test "新しいパスワードと確認が一致しない場合は変更できない" do
    patch update_password_admin_profile_path, params: {
      user: {
        current_password: "Password123!",
        password: "NewPassword456!",
        password_confirmation: "MismatchPassword!"
      }
    }

    assert_response :unprocessable_entity
    assert @owner.reload.valid_password?("Password123!")
  end

  test "未ログイン状態ではアクセスできない" do
    sign_out @owner

    get edit_password_admin_profile_path
    assert_redirected_to new_user_session_path
  end
end
