require "test_helper"

class I18nErrorMessagesTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Locale Tenant",
      code: "locale-tenant",
      subdomain: "locale",
      plan: "standard",
      status: "active",
      billing_email: "owner@locale.example.com"
    )

    @user = User.create!(
      tenant: @tenant,
      name: "Locale User",
      email: "user@locale.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )
  end

  test "login failure message is displayed in Japanese" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "WrongPassword!"
      }
    }

    assert_includes response.body, "メールアドレスまたはパスワードが正しくありません。"
  end
end
