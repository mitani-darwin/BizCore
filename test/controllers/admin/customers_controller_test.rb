require "test_helper"

class Admin::CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Customer Tenant",
      code: "customer-tenant",
      subdomain: "customer",
      plan: "standard",
      status: "active",
      billing_email: "owner@customer.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Customer Owner",
      email: "owner@customer.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer = @tenant.customers.create!(
      code: "C100",
      name: "青空商事",
      name_kana: "アオゾラショウジ",
      status: "active",
      email: "sales@aozora.example.com",
      contact_person_department: "営業部",
      contact_person_name: "山田花子",
      contact_person_email: "hanako@aozora.example.com",
      contact_person_tel: "03-0000-1111",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )

    @inactive_customer = @tenant.customers.create!(
      code: "C200",
      name: "休眠取引先",
      status: "inactive",
      contact_person_name: "佐藤次郎",
      closing_day: 20,
      payment_method: "direct_debit",
      payment_due_rule: "end_of_month",
      invoice_delivery_method: "postal"
    )

    @product = @tenant.products.create!(
      code: "P100",
      name: "標準商品",
      unit_name: "個",
      standard_price: 1000,
      tax_category: "taxable_10",
      active: true
    )

    @order = @tenant.orders.create!(
      customer: @customer,
      order_date: Date.new(2026, 4, 10),
      status: "accepted"
    )
    @order.order_items.create!(
      tenant: @tenant,
      product: @product,
      quantity: 2,
      unit_price: 1000
    )

    @invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: Date.new(2026, 5, 31),
      status: "partially_paid",
      subtotal_amount: 2000,
      tax_amount: 200,
      total_amount: 2200,
      paid_amount: 1000,
      balance_amount: 1200
    )

    @payment = @tenant.payments.create!(
      customer: @customer,
      payment_date: Date.new(2026, 5, 20),
      amount: 1000,
      status: "partially_applied",
      payment_method: "bank_transfer"
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "customer index filters by keyword and status" do
    get admin_customers_path, params: { q: "山田", status: "active" }
    assert_response :success

    assert_select "tbody tr", count: 1
    assert_select "tbody", text: /青空商事/
    assert_select "tbody", text: /休眠取引先/, count: 0
    assert_select "div", text: /売掛残高/
    assert_select "div", text: /¥1,200/
  end

  test "customer show displays transaction summary and recent history" do
    get admin_customer_path(@customer)
    assert_response :success

    assert_select "h1", text: "青空商事"
    assert_select "div", text: /売掛残高/
    assert_select "div", text: /¥1,200/
    assert_select "div", text: /営業部 山田花子/
    assert_select "a", text: @order.order_number
    assert_select "a", text: @invoice.invoice_number
    assert_select "a", text: @payment.payment_number
  end

  test "customer create accepts contact fields and status" do
    assert_difference("Customer.count", 1) do
      post admin_customers_path, params: {
        customer: {
          code: "C300",
          name: "新規取引先",
          status: "active",
          email: "new@example.com",
          contact_person_department: "購買部",
          contact_person_name: "田中一郎",
          contact_person_email: "tanaka@example.com",
          contact_person_tel: "03-0000-2222",
          closing_day: 25,
          payment_method: "bank_transfer",
          payment_due_rule: "next_month_end",
          invoice_delivery_method: "email"
        }
      }
    end

    customer = Customer.order(:id).last
    assert_redirected_to admin_customer_path(customer)
    assert_equal "田中一郎", customer.contact_person_name
    assert customer.active?
  end
end
