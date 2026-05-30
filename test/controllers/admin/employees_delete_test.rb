require "test_helper"

class Admin::EmployeesDeleteTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "従業員削除テナント",
      code: "emp-delete-test",
      subdomain: "emp-delete-test",
      plan: "standard",
      status: "active",
      billing_email: "billing@emp-delete-test.example.com"
    )
    @owner = User.create!(
      tenant: @tenant,
      name: "オーナー",
      email: "owner@emp-delete-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )
    @employee = @tenant.employees.create!(
      employee_code: "EMP-DEL-1",
      name: "削除対象従業員",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.current,
      base_hourly_wage: 1_000,
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )
    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "関連データなしの従業員は削除できる" do
    assert_difference -> { @tenant.employees.count }, -1 do
      delete admin_employee_path(@employee)
    end
    assert_redirected_to admin_employees_path
    assert_match "削除しました", flash[:notice]
  end

  test "削除後は従業員一覧にリダイレクトされる" do
    delete admin_employee_path(@employee)
    follow_redirect!
    assert_response :success
  end

  test "勤怠実績がある従業員は削除できない" do
    @tenant.attendance_records.create!(
      employee: @employee,
      work_date: Date.current,
      status: "closed",
      break_minutes: 60,
      worked_minutes: 480,
      overtime_minutes: 0
    )

    assert_no_difference -> { @tenant.employees.count } do
      delete admin_employee_path(@employee)
    end
    assert_redirected_to admin_employee_path(@employee)
    assert_match "勤怠実績", flash[:alert]
    assert_match "削除できません", flash[:alert]
  end

  test "給与明細がある従業員は削除できない" do
    run = @tenant.payroll_runs.create!(
      payroll_month: Date.current.beginning_of_month,
      status: "generated",
      employee_count: 1,
      total_gross_pay: 200_000
    )
    run.payroll_entries.create!(
      tenant: @tenant,
      employee: @employee,
      worked_minutes: 160 * 60,
      overtime_minutes: 0,
      paid_leave_days: 0,
      base_pay: 200_000,
      overtime_pay: 0,
      paid_leave_pay: 0,
      gross_pay: 200_000
    )

    assert_no_difference -> { @tenant.employees.count } do
      delete admin_employee_path(@employee)
    end
    assert_redirected_to admin_employee_path(@employee)
    assert_match "給与明細", flash[:alert]
  end

  test "関連ユーザーは nullify されて従業員が削除される" do
    user = User.create!(
      tenant: @tenant,
      employee: @employee,
      name: "紐付きユーザー",
      email: "linked@emp-delete-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )

    assert_difference -> { @tenant.employees.count }, -1 do
      delete admin_employee_path(@employee)
    end
    assert_nil user.reload.employee_id, "従業員削除後にユーザーの employee_id は nil になるべき"
  end

  test "日報・経費精算は cascade 削除される" do
    site = @tenant.sites.create!(code: "SITE-D1", name: "現場", category: "other", status: "active", progress_percentage: 0)
    @tenant.daily_reports.create!(site: site, employee: @employee, report_date: Date.current, work_content: "作業", work_hours: 8)
    @tenant.expense_reports.create!(employee: @employee, expensed_on: Date.current, category: "transportation", description: "交通費", amount: 500, status: "pending")

    assert_difference -> { @tenant.employees.count }, -1 do
      delete admin_employee_path(@employee)
    end
    assert_redirected_to admin_employees_path
  end

  test "deletable? は関連データなしで true を返す" do
    assert @employee.deletable?
  end

  test "deletable? は勤怠実績ありで false を返す" do
    @tenant.attendance_records.create!(
      employee: @employee,
      work_date: Date.current,
      status: "closed",
      break_minutes: 60,
      worked_minutes: 480,
      overtime_minutes: 0
    )
    assert_not @employee.reload.deletable?
  end

  test "deletion_blocked_reason は削除可能な場合 nil を返す" do
    assert_nil @employee.deletion_blocked_reason
  end
end
