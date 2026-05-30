require "test_helper"

class Imports::EmployeeImportTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "インポートテナント",
      code: "import-test",
      subdomain: "import-test",
      plan: "standard",
      status: "active",
      billing_email: "billing@import-test.example.com"
    )
  end

  test "正常な CSV を取り込める" do
    csv = <<~CSV
      従業員番号,氏名,雇用形態(hourly/salaried),在籍状況(active/inactive),入社日(YYYY/MM/DD),時給,月給,メール,電話番号
      EMP001,山田太郎,hourly,active,2024/04/01,1200,,yamada@example.com,090-0000-0001
      EMP002,鈴木花子,salaried,active,2024/04/01,,280000,suzuki@example.com,
    CSV

    result = Imports::EmployeeImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 2, result.total
    assert_equal 2, result.succeeded
    assert_empty result.failed_rows

    emp1 = @tenant.employees.find_by(employee_code: "EMP001")
    assert_not_nil emp1
    assert_equal "山田太郎", emp1.name
    assert_equal "hourly", emp1.employment_type
    assert_in_delta 1200, emp1.base_hourly_wage.to_f

    emp2 = @tenant.employees.find_by(employee_code: "EMP002")
    assert_equal "salaried", emp2.employment_type
    assert_in_delta 280000, emp2.base_monthly_salary.to_f
  end

  test "既存の従業員番号は更新される" do
    @tenant.employees.create!(
      employee_code: "EMP001",
      name: "旧名前",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.new(2024, 1, 1),
      base_hourly_wage: 1000,
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )

    csv = <<~CSV
      従業員番号,氏名,雇用形態(hourly/salaried),在籍状況(active/inactive),入社日(YYYY/MM/DD),時給,月給,メール,電話番号
      EMP001,新しい名前,hourly,active,2024/04/01,1500,,,
    CSV

    result = Imports::EmployeeImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 1, result.succeeded
    assert_equal "新しい名前", @tenant.employees.find_by(employee_code: "EMP001").name
  end

  test "従業員番号が空の行はエラー" do
    csv = <<~CSV
      従業員番号,氏名,雇用形態(hourly/salaried),在籍状況(active/inactive),入社日(YYYY/MM/DD),時給,月給,メール,電話番号
      ,氏名なし,hourly,active,,,,
    CSV

    result = Imports::EmployeeImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 0, result.succeeded
    assert_equal 1, result.failed_rows.size
    assert_includes result.failed_rows.first[:errors].first, "従業員番号"
  end

  test "バリデーションエラーは failed_rows に記録される" do
    csv = <<~CSV
      従業員番号,氏名,雇用形態(hourly/salaried),在籍状況(active/inactive),入社日(YYYY/MM/DD),時給,月給,メール,電話番号
      EMP001,,hourly,active,,,,invalid-email
    CSV

    result = Imports::EmployeeImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 0, result.succeeded
    assert_equal 1, result.failed_rows.size
  end

  test "template_csv がヘッダー行とサンプル行を含む" do
    csv_string = Imports::EmployeeImport.template_csv
    rows = CSV.parse(csv_string, headers: false)

    assert rows.first.include?("従業員番号")
    assert rows.first.include?("氏名")
    assert_equal Imports::EmployeeImport::SAMPLE_ROWS.size + 1, rows.size
  end
end
