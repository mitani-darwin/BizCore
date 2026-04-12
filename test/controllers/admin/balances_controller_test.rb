require "test_helper"

class Admin::BalancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Balance Tenant",
      code: "balance-tenant",
      subdomain: "balance",
      plan: "standard",
      status: "active",
      billing_email: "owner@balance.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Balance Owner",
      email: "owner@balance.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer_with_overdue = @tenant.customers.create!(
      code: "C100",
      name: "青空商事",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )
    @customer_current_only = @tenant.customers.create!(
      code: "C200",
      name: "海風産業",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )

    @supplier_with_overdue = @tenant.suppliers.create!(
      code: "S100",
      name: "標準仕入先",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end"
    )
    @supplier_current_only = @tenant.suppliers.create!(
      code: "S200",
      name: "現行仕入先",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end"
    )

    create_invoice!(
      customer: @customer_with_overdue,
      due_date: Date.new(2026, 4, 30),
      total_amount: 1200,
      paid_amount: 0,
      balance_amount: 1200,
      status: "issued"
    )
    create_invoice!(
      customer: @customer_with_overdue,
      due_date: Date.new(2026, 6, 20),
      total_amount: 2200,
      paid_amount: 0,
      balance_amount: 2200,
      status: "issued"
    )
    create_invoice!(
      customer: @customer_current_only,
      due_date: Date.new(2026, 6, 25),
      total_amount: 3300,
      paid_amount: 0,
      balance_amount: 3300,
      status: "issued"
    )

    create_purchase_bill!(
      supplier: @supplier_with_overdue,
      due_date: Date.new(2026, 4, 25),
      total_amount: 550,
      paid_amount: 0,
      balance_amount: 550,
      status: "issued"
    )
    create_purchase_bill!(
      supplier: @supplier_with_overdue,
      due_date: Date.new(2026, 6, 15),
      total_amount: 880,
      paid_amount: 0,
      balance_amount: 880,
      status: "issued"
    )
    create_purchase_bill!(
      supplier: @supplier_current_only,
      due_date: Date.new(2026, 6, 30),
      total_amount: 1100,
      paid_amount: 0,
      balance_amount: 1100,
      status: "issued"
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "receivables index shows overdue balances and aging buckets" do
    get admin_receivables_path, params: {
      q: "商事",
      status: "active",
      balance_scope: "overdue",
      as_of: "2026-05-31"
    }
    assert_response :success

    assert_select "h1", text: "売掛残高一覧"
    assert_select "tbody tr", count: 1
    assert_select "tbody", text: /青空商事/
    assert_select "tbody", text: /海風産業/, count: 0
    assert_select "td", text: "¥3,400"
    assert_select "td", text: "¥1,200"
    assert_select "td", text: "¥2,200"
    assert_select "a[href='#{admin_customer_path(@customer_with_overdue)}']", text: "得意先詳細"
  end

  test "payables index shows overdue balances and aging buckets" do
    get admin_payables_path, params: {
      q: "標準",
      status: "active",
      balance_scope: "overdue",
      as_of: "2026-05-31"
    }
    assert_response :success

    assert_select "h1", text: "買掛残高一覧"
    assert_select "tbody tr", count: 1
    assert_select "tbody", text: /標準仕入先/
    assert_select "tbody", text: /現行仕入先/, count: 0
    assert_select "td", text: "¥1,430"
    assert_select "td", text: "¥550"
    assert_select "td", text: "¥880"
    assert_select "a[href='#{admin_supplier_path(@supplier_with_overdue)}']", text: "仕入先詳細"
  end

  private

  def create_invoice!(customer:, due_date:, total_amount:, paid_amount:, balance_amount:, status:)
    @tenant.invoices.create!(
      customer: customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: due_date,
      status: status,
      subtotal_amount: total_amount,
      tax_amount: 0,
      total_amount: total_amount,
      paid_amount: paid_amount,
      balance_amount: balance_amount
    )
  end

  def create_purchase_bill!(supplier:, due_date:, total_amount:, paid_amount:, balance_amount:, status:)
    @tenant.purchase_bills.create!(
      supplier: supplier,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      bill_date: Date.new(2026, 4, 30),
      due_date: due_date,
      status: status,
      subtotal_amount: total_amount,
      tax_amount: 0,
      total_amount: total_amount,
      paid_amount: paid_amount,
      balance_amount: balance_amount
    )
  end
end
