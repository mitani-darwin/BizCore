require "test_helper"

class LeaveRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Leave Request Tenant",
      code: "leave-request-tenant",
      subdomain: "leave-request",
      plan: "standard",
      status: "active",
      billing_email: "owner@leave-request.example.com"
    )

    @employee = @tenant.employees.create!(
      employee_code: "EMP-LEAVE-1",
      name: "有給申請者",
      status: "active",
      employment_type: "salaried",
      joined_on: Date.new(2026, 4, 1),
      base_hourly_wage: 0,
      base_monthly_salary: 300_000,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )
    @employee_user = User.create!(
      tenant: @tenant,
      employee: @employee,
      name: "有給申請ユーザー",
      email: "employee@leave-request.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo"
    )

    Permissions::Catalog.seed_admin!
  end

  test "employee can view leave request list" do
    sign_in @employee_user
    get my_leave_requests_path
    assert_response :success
    assert_select "h1", text: "マイ有給申請"
  end

  test "employee can view new leave request form" do
    sign_in @employee_user
    get new_my_leave_request_path
    assert_response :success
    assert_select "h1", text: "有給申請"
  end

  test "employee can create a leave request" do
    sign_in @employee_user
    assert_difference -> { @employee.leave_requests.count }, +1 do
      post my_leave_requests_path, params: {
        leave_request: {
          leave_type: "paid_leave",
          start_date: "2026-06-01",
          end_date: "2026-06-03",
          reason: "私用のため"
        }
      }
    end
    assert_redirected_to my_leave_requests_path

    leave_request = @employee.leave_requests.last
    assert_equal "paid_leave", leave_request.leave_type
    assert_equal "pending", leave_request.status
    assert_equal Date.new(2026, 6, 1), leave_request.start_date
  end

  test "employee can create a half-day leave request" do
    sign_in @employee_user
    assert_difference -> { @employee.leave_requests.count }, +1 do
      post my_leave_requests_path, params: {
        leave_request: {
          leave_type: "paid_leave",
          half_day_type: "morning",
          start_date: "2026-06-01",
          end_date: "2026-06-01",
          reason: "午前のみ"
        }
      }
    end
    assert_redirected_to my_leave_requests_path

    leave_request = @employee.leave_requests.last
    assert_equal "morning", leave_request.half_day_type
    assert_equal 0.5.to_d, leave_request.days_count
    assert_equal Date.new(2026, 6, 1), leave_request.start_date
    assert_equal Date.new(2026, 6, 1), leave_request.end_date
  end

  test "employee can view leave request detail" do
    sign_in @employee_user
    leave_request = @employee.leave_requests.create!(
      tenant: @tenant,
      leave_type: "paid_leave",
      start_date: Date.new(2026, 6, 1),
      end_date: Date.new(2026, 6, 1),
      days_count: 1,
      status: "pending",
      reason: "私用"
    )
    get my_leave_request_path(leave_request)
    assert_response :success
    assert_select "h1", text: "有給申請詳細"
  end

  test "unauthenticated user cannot access leave requests" do
    get my_leave_requests_path
    assert_response :not_found
  end
end
