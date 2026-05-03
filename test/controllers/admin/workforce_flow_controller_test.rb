require "test_helper"

class Admin::WorkforceFlowControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Workforce Tenant",
      code: "workforce-tenant",
      subdomain: "workforce",
      plan: "standard",
      status: "active",
      billing_email: "owner@workforce.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Workforce Owner",
      email: "owner@workforce.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "attendance leave and payroll flow works end to end" do
    assert_difference -> { @tenant.employees.count }, +1 do
      post admin_employees_path, params: {
        employee: {
          employee_code: "EMP-100",
          name: "山田 花子",
          status: "active",
          employment_type: "hourly",
          joined_on: "2026-04-01",
          base_hourly_wage: "1200",
          base_monthly_salary: "0",
          overtime_rate_multiplier: "1.25",
          standard_daily_minutes: "480",
          default_break_minutes: "60",
          paid_leave_granted_days: "10"
        }
      }
    end
    employee = @tenant.employees.find_by!(employee_code: "EMP-100")
    follow_redirect!
    assert_response :success
    assert_select "h1", text: /山田 花子/

    assert_difference -> { @tenant.work_shifts.count }, +1 do
      post admin_work_shifts_path, params: {
        work_shift: {
          employee_id: employee.id,
          work_date: "2026-04-10",
          start_time: "09:00",
          end_time: "18:00",
          break_minutes: "60",
          status: "scheduled"
        }
      }
    end
    work_shift = @tenant.work_shifts.find_by!(employee: employee, work_date: Date.new(2026, 4, 10))
    assert_equal 480, work_shift.scheduled_minutes

    assert_difference -> { @tenant.attendance_records.count }, +1 do
      post clock_in_admin_attendance_records_path, params: {
        employee_id: employee.id,
        clock_in_on: "2026-04-10",
        clock_in_time: "09:00"
      }
    end
    attendance_record = @tenant.attendance_records.find_by!(employee: employee, work_date: Date.new(2026, 4, 10))
    assert_equal "working", attendance_record.status

    patch clock_out_admin_attendance_record_path(attendance_record), params: {
      attendance_record: {
        clock_out_on: "2026-04-10",
        clock_out_time: "19:30",
        break_minutes: "60",
        note: "月初対応で残業"
      }
    }
    assert_redirected_to admin_attendance_record_path(attendance_record)
    attendance_record.reload
    assert_equal "closed", attendance_record.status
    assert_equal 570, attendance_record.worked_minutes
    assert_equal 90, attendance_record.overtime_minutes
    assert_equal work_shift.id, attendance_record.work_shift_id

    assert_difference -> { @tenant.leave_requests.count }, +1 do
      post admin_leave_requests_path, params: {
        leave_request: {
          employee_id: employee.id,
          start_date: "2026-04-11",
          end_date: "2026-04-11",
          days_count: "1",
          leave_type: "paid_leave",
          reason: "私用"
        }
      }
    end
    leave_request = @tenant.leave_requests.find_by!(employee: employee, start_date: Date.new(2026, 4, 11))

    patch approve_admin_leave_request_path(leave_request)
    assert_redirected_to admin_leave_request_path(leave_request)
    leave_request.reload
    assert_equal "approved", leave_request.status

    assert_difference -> { @tenant.payroll_runs.count }, +1 do
      post generate_admin_payroll_runs_path, params: {
        payroll_month: "2026-04",
        note: "2026年4月給与"
      }
    end
    payroll_run = @tenant.payroll_runs.find_by!(payroll_month: Date.new(2026, 4, 1))
    payroll_entry = payroll_run.payroll_entries.find_by!(employee: employee)

    assert_equal 1, payroll_run.employee_count
    assert_equal BigDecimal("21450.0"), payroll_run.total_gross_pay
    assert_equal 570, payroll_entry.worked_minutes
    assert_equal 90, payroll_entry.overtime_minutes
    assert_equal BigDecimal("1.0"), payroll_entry.paid_leave_days
    assert_equal BigDecimal("9600.0"), payroll_entry.base_pay
    assert_equal BigDecimal("2250.0"), payroll_entry.overtime_pay
    assert_equal BigDecimal("9600.0"), payroll_entry.paid_leave_pay
    assert_equal BigDecimal("21450.0"), payroll_entry.gross_pay

    follow_redirect!
    assert_response :success
    assert_select "h1", text: /#{payroll_run.run_number}/
    assert_select "td", text: /山田 花子/

    get admin_payroll_runs_path
    assert_response :success
    assert_select "h1", text: "給与計算一覧"
  end

  test "attendance uses shift break minutes when shift break differs from employee default" do
    employee = @tenant.employees.create!(
      employee_code: "EMP-200",
      name: "休憩差分テスト",
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

    @tenant.work_shifts.create!(
      employee: employee,
      work_date: Date.new(2026, 4, 12),
      start_time: "09:00",
      end_time: "18:00",
      break_minutes: 90,
      status: "scheduled"
    )

    post clock_in_admin_attendance_records_path, params: {
      employee_id: employee.id,
      clock_in_on: "2026-04-12",
      clock_in_time: "09:00"
    }
    assert_redirected_to admin_attendance_record_path(AttendanceRecord.last)

    attendance_record = @tenant.attendance_records.find_by!(employee: employee, work_date: Date.new(2026, 4, 12))
    assert_equal 90, attendance_record.break_minutes

    patch clock_out_admin_attendance_record_path(attendance_record), params: {
      attendance_record: {
        clock_out_on: "2026-04-12",
        clock_out_time: "18:00",
        break_minutes: "90"
      }
    }
    assert_redirected_to admin_attendance_record_path(attendance_record)

    attendance_record.reload
    assert_equal 450, attendance_record.worked_minutes
    assert_equal 0, attendance_record.overtime_minutes
  end
end
