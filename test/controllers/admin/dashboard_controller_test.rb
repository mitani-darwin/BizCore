require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "ダッシュボードテナント",
      code: "dashboard-tenant",
      subdomain: "dashboard",
      plan: "standard",
      status: "active",
      billing_email: "billing@dashboard.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "オーナー",
      email: "owner@dashboard.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )

    Permissions::Catalog.seed_admin!
  end

  test "owner can access dashboard" do
    sign_in @owner
    get admin_root_path
    assert_response :success
  end

  test "dashboard shows KPI cards for owner" do
    sign_in @owner
    get admin_root_path
    assert_response :success
    assert_select "p", text: /承認待ち申請/
  end

  test "dashboard shows pending leave requests" do
    employee = @tenant.employees.create!(
      employee_code: "EMP-DSH-1",
      name: "テスト従業員",
      status: "active",
      employment_type: "hourly",
      joined_on: Date.new(2026, 4, 1),
      base_hourly_wage: 1_500,
      base_monthly_salary: 0,
      overtime_rate_multiplier: 1.25,
      standard_daily_minutes: 480,
      default_break_minutes: 60,
      paid_leave_granted_days: 10
    )
    @tenant.leave_requests.create!(
      employee: employee,
      leave_type: "paid_leave",
      start_date: Date.current + 7,
      end_date: Date.current + 7,
      days_count: 1,
      status: "pending"
    )

    sign_in @owner
    get admin_root_path
    assert_response :success
    assert_select "h2", text: /有給申請（承認待ち）/
  end

  test "dashboard shows low stock alert when stock is below safety level" do
    warehouse = @tenant.warehouses.create!(code: "WH-DSH", name: "テスト倉庫")
    product = @tenant.products.create!(
      code: "PRD-DSH-1",
      name: "在庫不足商品",
      unit_name: "個",
      standard_price: 1_000
    )
    @tenant.stock_items.create!(
      warehouse: warehouse,
      product: product,
      quantity_on_hand: 2,
      quantity_reserved: 0,
      safety_stock: 5
    )

    sign_in @owner
    get admin_root_path
    assert_response :success
    assert_select "h2", text: /在庫アラート/
  end

  test "dashboard shows expiring contract alert" do
    customer = @tenant.customers.create!(
      code: "CUST-DSH-1",
      name: "期限間近顧客",
      status: "active"
    )
    @tenant.contracts.create!(
      contract_number: "CNT-DSH-001",
      title: "期限間近の契約",
      counterparty_type: "customer",
      customer: customer,
      status: "active",
      started_on: Date.current - 365,
      ended_on: Date.current + 15
    )

    sign_in @owner
    get admin_root_path
    assert_response :success
    assert_select "h2", text: /契約期限アラート/
  end

  test "unauthenticated user cannot access dashboard" do
    get admin_root_path
    assert_response :redirect
  end
end
