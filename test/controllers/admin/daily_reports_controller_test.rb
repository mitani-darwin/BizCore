require "test_helper"

class Admin::DailyReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "DailyReport Tenant",
      code: "dr-admin-test",
      subdomain: "dr-admin-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@dr-admin-test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "DR Admin Owner",
      email: "owner@dr-admin-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @site = @tenant.sites.create!(
      name: "テスト現場",
      code: "SITE-001",
      category: "construction",
      status: "active"
    )

    @employee = @tenant.employees.create!(
      name: "テスト従業員",
      employee_code: "EMP-001",
      email: "emp@dr-admin-test.example.com",
      status: "active",
      employment_type: "salaried",
      base_hourly_wage: 0,
      base_monthly_salary: 300_000,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10,
      joined_on: Date.current.prev_month
    )

    @daily_report = @tenant.daily_reports.create!(
      site: @site,
      employee: @employee,
      report_date: Date.current,
      work_content: "外壁の補修作業を実施しました。",
      work_hours: 7.5
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  # index のテスト
  test "index が成功する" do
    get admin_daily_reports_path
    assert_response :success
    assert_select "h1", text: "日報一覧"
    assert_select "td", text: /外壁の補修作業/
  end

  test "index は site_id でフィルタできる" do
    other_site = @tenant.sites.create!(name: "別現場", code: "SITE-002", category: "maintenance", status: "active")
    @tenant.daily_reports.create!(
      site: other_site,
      employee: @employee,
      report_date: Date.current - 1,
      work_content: "設備点検を実施",
      work_hours: 8.0
    )

    get admin_daily_reports_path, params: { site_id: @site.id }
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: /外壁の補修作業/
  end

  test "index は作業内容キーワードでフィルタできる" do
    get admin_daily_reports_path, params: { q: "外壁" }
    assert_response :success
    assert_select "tbody tr", count: 1
  end

  # show のテスト
  test "show が成功する" do
    get admin_daily_report_path(@daily_report)
    assert_response :success
    assert_select "h1", text: "日報詳細"
  end

  test "他テナントの日報は 404 になる" do
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-dr-admin",
      subdomain: "other-dr-admin",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-dr-admin.example.com"
    )
    other_site = other_tenant.sites.create!(name: "他の現場", code: "S-001", category: "construction", status: "active")
    other_employee = other_tenant.employees.create!(
      name: "他の従業員",
      employee_code: "EMP-001",
      email: "emp@other-dr-admin.example.com",
      status: "active",
      employment_type: "salaried",
      base_hourly_wage: 0,
      base_monthly_salary: 300_000,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10,
      joined_on: Date.current.prev_month
    )
    other_report = other_tenant.daily_reports.create!(
      site: other_site,
      employee: other_employee,
      report_date: Date.current,
      work_content: "他テナントの作業",
      work_hours: 8.0
    )

    get admin_daily_report_path(other_report)
    assert_response :not_found
  end
end
