require "test_helper"

class DailyReportTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "日報テナント",
      code: "dr-test",
      subdomain: "dr-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@dr-test.example.com"
    )

    @site = @tenant.sites.create!(
      name: "テスト現場",
      code: "S-001",
      category: "construction",
      status: "active"
    )

    @employee = @tenant.employees.create!(
      name: "テスト従業員",
      employee_code: "EMP-001",
      email: "employee@dr-test.example.com",
      status: "active",
      employment_type: "salaried",
      base_hourly_wage: 0,
      base_monthly_salary: 300_000,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10,
      joined_on: Date.current.prev_month
    )
  end

  # バリデーション: report_date は必須
  test "report_date は必須" do
    report = DailyReport.new(
      tenant: @tenant,
      site: @site,
      employee: @employee,
      work_content: "外壁の補修作業を実施",
      work_hours: 8.0
    )
    assert_not report.valid?
    assert_includes report.errors[:report_date], "を入力してください"
  end

  # バリデーション: work_content は必須
  test "work_content は必須" do
    report = DailyReport.new(
      tenant: @tenant,
      site: @site,
      employee: @employee,
      report_date: Date.current,
      work_hours: 8.0
    )
    assert_not report.valid?
    assert_includes report.errors[:work_content], "を入力してください"
  end

  # バリデーション: work_hours は 0より大きい
  test "work_hours は 0 より大きい" do
    report = DailyReport.new(
      tenant: @tenant,
      site: @site,
      employee: @employee,
      report_date: Date.current,
      work_content: "外壁の補修作業を実施",
      work_hours: 0
    )
    assert_not report.valid?
    assert report.errors[:work_hours].any?
  end

  test "work_hours が負の値の場合もバリデーションエラー" do
    report = DailyReport.new(
      tenant: @tenant,
      site: @site,
      employee: @employee,
      report_date: Date.current,
      work_content: "外壁の補修作業を実施",
      work_hours: -1.0
    )
    assert_not report.valid?
    assert report.errors[:work_hours].any?
  end

  # 正常なレコードが保存できる
  test "有効なデータで日報を保存できる" do
    report = DailyReport.new(
      tenant: @tenant,
      site: @site,
      employee: @employee,
      report_date: Date.current,
      work_content: "外壁の補修作業を実施しました。",
      work_hours: 7.5
    )
    assert report.valid?
    assert report.save
  end

  # ordered_for_admin スコープのテスト
  test "ordered_for_admin は report_date の降順で返す" do
    r1 = DailyReport.create!(
      tenant: @tenant, site: @site, employee: @employee,
      report_date: Date.current - 2, work_content: "作業1", work_hours: 8.0
    )
    r2 = DailyReport.create!(
      tenant: @tenant, site: @site, employee: @employee,
      report_date: Date.current - 1, work_content: "作業2", work_hours: 8.0
    )
    r3 = DailyReport.create!(
      tenant: @tenant, site: @site, employee: @employee,
      report_date: Date.current, work_content: "作業3", work_hours: 8.0
    )

    ordered = DailyReport.ordered_for_admin.to_a
    dates = ordered.map(&:report_date)
    assert_equal dates.sort.reverse, dates
  end
end
