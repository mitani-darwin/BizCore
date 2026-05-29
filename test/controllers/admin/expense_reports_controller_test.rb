require "test_helper"

class Admin::ExpenseReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Expense Tenant",
      code: "expense-test",
      subdomain: "expense-test",
      plan: "standard",
      status: "active",
      billing_email: "owner@expense-test.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Expense Owner",
      email: "owner@expense-test.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @employee = @tenant.employees.create!(
      name: "田中 太郎",
      employee_code: "EMP-001",
      employment_type: "hourly",
      status: "active",
      joined_on: Date.current,
      base_hourly_wage: 1000
    )

    @expense_report = @tenant.expense_reports.create!(
      employee: @employee,
      expensed_on: Date.current,
      category: "transportation",
      description: "東京駅〜新宿駅 往復",
      amount: 1500,
      status: "pending"
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "index が成功する" do
    get admin_expense_reports_path
    assert_response :success
    assert_select "h1", text: "経費精算一覧"
    assert_select "td", text: /東京駅〜新宿駅/
  end

  test "show が成功する" do
    get admin_expense_report_path(@expense_report)
    assert_response :success
    assert_select "h1", text: /田中 太郎/
  end

  test "他テナントの経費申請は 404 になる" do
    other_tenant = Tenant.create!(
      name: "他テナント",
      code: "other-exp",
      subdomain: "other-exp",
      plan: "standard",
      status: "active",
      billing_email: "owner@other-exp.example.com"
    )
    other_employee = other_tenant.employees.create!(
      name: "山田 花子",
      employee_code: "EMP-001",
      employment_type: "hourly",
      status: "active",
      joined_on: Date.current,
      base_hourly_wage: 1000
    )
    other_report = other_tenant.expense_reports.create!(
      employee: other_employee,
      expensed_on: Date.current,
      category: "other",
      description: "他テナントの経費",
      amount: 1000,
      status: "pending"
    )

    get admin_expense_report_path(other_report)
    assert_response :not_found
  end

  test "new が成功する" do
    get new_admin_expense_report_path
    assert_response :success
    assert_select "h1", text: "経費精算新規作成"
  end

  test "有効なパラメータで経費申請を作成できる" do
    assert_difference("ExpenseReport.count", 1) do
      post admin_expense_reports_path, params: {
        expense_report: {
          employee_id: @employee.id,
          expensed_on: Date.current.to_s,
          category: "transportation",
          description: "渋谷駅〜品川駅",
          amount: 500
        }
      }
    end

    report = ExpenseReport.order(:id).last
    assert_redirected_to admin_expense_report_path(report)
    assert_equal "pending", report.status
    assert_equal @tenant.id, report.tenant_id
  end

  test "無効なパラメータでは経費申請を作成できない" do
    assert_no_difference("ExpenseReport.count") do
      post admin_expense_reports_path, params: {
        expense_report: { employee_id: @employee.id, expensed_on: Date.current.to_s, category: "transportation", description: "", amount: 0 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "approve で承認できる" do
    patch approve_admin_expense_report_path(@expense_report)
    assert_redirected_to admin_expense_report_path(@expense_report)
    assert_equal "approved", @expense_report.reload.status
  end

  test "reject で却下できる" do
    patch reject_admin_expense_report_path(@expense_report)
    assert_redirected_to admin_expense_report_path(@expense_report)
    assert_equal "rejected", @expense_report.reload.status
  end
end
