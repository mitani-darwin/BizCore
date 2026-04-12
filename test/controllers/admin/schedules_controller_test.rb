require "test_helper"

class Admin::SchedulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Schedule Tenant",
      code: "schedule-tenant",
      subdomain: "schedule",
      plan: "standard",
      status: "active",
      billing_email: "owner@schedule.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Schedule Owner",
      email: "owner@schedule.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer = @tenant.customers.create!(
      code: "C100",
      name: "青空商事",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )
    @supplier = @tenant.suppliers.create!(
      code: "S100",
      name: "標準仕入先",
      status: "active",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end"
    )

    @overdue_invoice = create_invoice!(
      customer: @customer,
      due_date: Date.new(2026, 5, 25),
      total_amount: 1200
    )
    @today_invoice = create_invoice!(
      customer: @customer,
      due_date: Date.new(2026, 5, 31),
      total_amount: 2200
    )
    @within_week_invoice = create_invoice!(
      customer: @customer,
      due_date: Date.new(2026, 6, 5),
      total_amount: 1500
    )

    @overdue_purchase_bill = create_purchase_bill!(
      supplier: @supplier,
      due_date: Date.new(2026, 5, 20),
      total_amount: 550
    )
    @today_purchase_bill = create_purchase_bill!(
      supplier: @supplier,
      due_date: Date.new(2026, 5, 31),
      total_amount: 880
    )
    @within_week_purchase_bill = create_purchase_bill!(
      supplier: @supplier,
      due_date: Date.new(2026, 6, 4),
      total_amount: 990
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "collection schedules show invoices by due condition" do
    get admin_collection_schedules_path, params: {
      q: "青空",
      schedule_scope: "within_7_days",
      as_of: "2026-05-31"
    }
    assert_response :success

    assert_select "h1", text: "回収予定表"
    assert_select "tbody tr", count: 2
    assert_select "a", text: @today_invoice.invoice_number
    assert_select "a", text: @within_week_invoice.invoice_number
    assert_select "a", text: @overdue_invoice.invoice_number, count: 0
    assert_select "div", text: /¥3,700/
  end

  test "payment schedules show overdue bills" do
    get admin_payment_schedules_path, params: {
      q: "標準",
      schedule_scope: "overdue",
      as_of: "2026-05-31"
    }
    assert_response :success

    assert_select "h1", text: "支払予定表"
    assert_select "tbody tr", count: 1
    assert_select "a", text: @overdue_purchase_bill.bill_number
    assert_select "a", text: @today_purchase_bill.bill_number, count: 0
    assert_select "div", text: /¥550/
  end

  private

  def create_invoice!(customer:, due_date:, total_amount:)
    @tenant.invoices.create!(
      customer: customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: due_date,
      status: "issued",
      subtotal_amount: total_amount,
      tax_amount: 0,
      total_amount: total_amount,
      paid_amount: 0,
      balance_amount: total_amount
    )
  end

  def create_purchase_bill!(supplier:, due_date:, total_amount:)
    @tenant.purchase_bills.create!(
      supplier: supplier,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      bill_date: Date.new(2026, 4, 30),
      due_date: due_date,
      status: "issued",
      subtotal_amount: total_amount,
      tax_amount: 0,
      total_amount: total_amount,
      paid_amount: 0,
      balance_amount: total_amount
    )
  end
end
