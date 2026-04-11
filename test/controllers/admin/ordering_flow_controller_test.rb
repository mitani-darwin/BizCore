require "test_helper"

class Admin::OrderingFlowControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Order Tenant",
      code: "order-tenant",
      subdomain: "order",
      plan: "standard",
      status: "active",
      billing_email: "owner@order.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Order Owner",
      email: "owner@order.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @customer = @tenant.customers.create!(
      code: "C001",
      name: "テスト得意先",
      email: "customer@example.com",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )
    @product = @tenant.products.create!(
      code: "P001",
      name: "標準商品",
      unit_name: "個",
      standard_price: 1000,
      tax_category: "taxable_10",
      active: true
    )
    @warehouse = @tenant.warehouses.create!(
      code: "W001",
      name: "本社倉庫",
      active: true
    )
    @stock_item = @tenant.stock_items.create!(
      warehouse: @warehouse,
      product: @product,
      quantity_on_hand: 10,
      quantity_reserved: 0
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "ordering management screens render" do
    get admin_customers_path
    assert_response :success

    get admin_customer_path(@customer)
    assert_response :success

    get admin_products_path
    assert_response :success

    get admin_product_path(@product)
    assert_response :success

    get admin_warehouses_path
    assert_response :success

    get admin_warehouse_path(@warehouse)
    assert_response :success

    get admin_stock_items_path
    assert_response :success

    get new_admin_stock_item_path
    assert_response :success

    get admin_orders_path
    assert_response :success

    get new_admin_order_path
    assert_response :success

    get admin_deliveries_path
    assert_response :success

    get admin_invoices_path
    assert_response :success

    get admin_payments_path
    assert_response :success

    get new_admin_payment_path
    assert_response :success
  end

  test "admin ordering flow proceeds from order to reconciliation" do
    assert_difference("Order.count", 1) do
      post admin_orders_path, params: {
        order: {
          customer_id: @customer.id,
          order_date: "2026-04-11",
          requested_delivery_date: "2026-04-12",
          ordered_by_name: "購買担当",
          delivery_address: "東京都港区1-2-3",
          remarks: "画面経由の注文",
          order_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 2,
              unit_price: 1000
            },
            "1" => {
              product_id: "",
              quantity: "",
              unit_price: ""
            }
          }
        }
      }
    end

    order = Order.order(:id).last
    assert_redirected_to admin_order_path(order)

    get admin_order_path(order)
    assert_response :success

    patch send_order_admin_order_path(order)
    assert_redirected_to admin_order_path(order)
    assert order.reload.sent?

    patch accept_order_admin_order_path(order)
    assert_redirected_to admin_order_path(order)
    assert order.reload.accepted?

    patch reserve_stock_admin_order_path(order), params: { warehouse_id: @warehouse.id }
    assert_redirected_to admin_order_path(order)
    assert order.reload.allocated?

    assert_difference("Delivery.count", 1) do
      patch issue_delivery_admin_order_path(order), params: { delivery_date: "2026-04-12" }
    end

    delivery = Delivery.order(:id).last
    assert_redirected_to admin_delivery_path(delivery)

    get admin_delivery_path(delivery)
    assert_response :success

    assert_difference("Invoice.count", 1) do
      post issue_monthly_admin_invoices_path, params: {
        billing_period_from: "2026-04-01",
        billing_period_to: "2026-04-30",
        closing_date: "2026-04-30",
        invoice_date: "2026-04-30",
        due_date: "2026-05-31"
      }
    end

    assert_redirected_to admin_invoices_path

    invoice = Invoice.order(:id).last
    get admin_invoice_path(invoice)
    assert_response :success

    assert_difference("Payment.count", 1) do
      post admin_payments_path, params: {
        payment: {
          customer_id: @customer.id,
          payment_date: "2026-05-20",
          amount: 2200,
          payment_method: "bank_transfer",
          bank_name: "テスト銀行",
          account_name: "テスト口座",
          reference_note: "一括入金"
        }
      }
    end

    payment = Payment.order(:id).last
    assert_redirected_to admin_payment_path(payment)

    get admin_payment_path(payment)
    assert_response :success

    patch reconcile_admin_payment_path(payment), params: {
      allocations: {
        invoice.id.to_s => "2200"
      }
    }
    assert_redirected_to admin_payment_path(payment)

    assert payment.reload.applied?
    assert invoice.reload.paid?
  end
end
