require "test_helper"

class SelfAttendanceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Self Attendance Tenant",
      code: "self-attendance-tenant",
      subdomain: "self-attendance",
      plan: "standard",
      status: "active",
      billing_email: "owner@self-attendance.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Self Attendance Owner",
      email: "owner@self-attendance.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @employee = @tenant.employees.create!(
      employee_code: "EMP-SELF-1",
      name: "従業員打刻",
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
    @employee_user = User.create!(
      tenant: @tenant,
      employee: @employee,
      name: "従業員打刻ユーザー",
      email: "employee@self-attendance.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo"
    )

    @tenant.work_shifts.create!(
      employee: @employee,
      work_date: Date.new(2026, 4, 15),
      start_time: "09:00",
      end_time: "18:00",
      break_minutes: 60,
      status: "scheduled"
    )

    Permissions::Catalog.seed_admin!
  end

  test "employee user root redirects to self attendance and can clock in and out" do
    sign_in @employee_user

    get root_path
    assert_redirected_to my_attendance_path

    follow_redirect!
    assert_response :success
    assert_select "h1", text: "マイ打刻"
    assert_select "p", text: /従業員打刻/

    assert_difference -> { @employee.attendance_records.count }, +1 do
      post clock_in_my_attendance_path, params: {
        clock_in_on: "2026-04-15",
        clock_in_time: "09:00"
      }
    end
    attendance_record = @employee.attendance_records.find_by!(work_date: Date.new(2026, 4, 15))
    assert_equal "working", attendance_record.status
    assert_equal 60, attendance_record.break_minutes

    patch clock_out_my_attendance_path, params: {
      attendance_record: {
        attendance_record_id: attendance_record.id,
        clock_out_on: "2026-04-15",
        clock_out_time: "18:30",
        break_minutes: "60",
        note: "棚卸対応"
      }
    }
    assert_redirected_to my_attendance_path(date: Date.new(2026, 4, 15))

    attendance_record.reload
    assert_equal "closed", attendance_record.status
    assert_equal 510, attendance_record.worked_minutes
    assert_equal 30, attendance_record.overtime_minutes
  end

  test "admin user root redirects to admin dashboard" do
    sign_in @owner

    get root_path
    assert_redirected_to admin_root_path
  end
end
