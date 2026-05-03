require "test_helper"

class EmployeeSignInTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Employee Sign In Tenant",
      code: "employee-sign-in-tenant",
      subdomain: "employee-sign-in",
      plan: "standard",
      status: "active",
      billing_email: "owner@employee-sign-in.example.com"
    )

    @employee = @tenant.employees.create!(
      employee_code: "EMP-SIGNIN-1",
      name: "従業員ログイン確認",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.new(2026, 4, 1),
      base_hourly_wage: 1200,
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )

    @user = User.create!(
      tenant: @tenant,
      employee: @employee,
      name: "従業員ログインユーザー",
      email: "employee-signin@example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo"
    )
  end

  test "employee can sign in from devise session form and is redirected to self attendance" do
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "Password123!"
      }
    }

    assert_redirected_to root_path

    follow_redirect!
    assert_redirected_to my_attendance_path

    follow_redirect!
    assert_response :success
    assert_select "h1", text: "マイ打刻"
    assert_select "p", text: /従業員ログイン確認/
  end
end
