require "zip"

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
    @quotation = @tenant.quotations.create!(
      customer: @customer,
      subject: "定番商品のご提案",
      quotation_date: Date.new(2026, 4, 10),
      expiration_date: Date.new(2026, 4, 30),
      quoted_by_name: "営業担当"
    )
    @quotation.quotation_items.create!(
      tenant: @tenant,
      product: @product,
      quantity: 1,
      unit_price: 1000
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

    get admin_quotations_path
    assert_response :success

    get admin_quotation_path(@quotation)
    assert_response :success

    get download_excel_admin_quotation_path(@quotation)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_includes response.headers["Content-Disposition"], "#{@quotation.quotation_number}.xlsx"
    assert_equal "PK", response.body.byteslice(0, 2)
    assert_includes zip_entry_content(response.body, "xl/worksheets/sheet1.xml"), @quotation.quotation_number

    get new_admin_quotation_path
    assert_response :success
    assert_select "tbody[data-order-items-target='rows'] > tr[data-order-items-target='row']", count: 1
    assert_select "button[data-action='order-items#addRow']", text: "明細を追加"

    get admin_orders_path
    assert_response :success

    get new_admin_order_path
    assert_response :success
    assert_select "tbody[data-order-items-target='rows'] > tr[data-order-items-target='row']", count: 1
    assert_select "button[data-action='order-items#addRow']", text: "明細を追加"

    get admin_deliveries_path
    assert_response :success

    get admin_invoices_path
    assert_response :success

    get admin_payments_path
    assert_response :success

    get new_admin_payment_path
    assert_response :success
  end

  test "quotation flow proceeds from quotation to order conversion" do
    assert_difference("Quotation.count", 1) do
      assert_difference("QuotationItem.count", 1) do
        post admin_quotations_path, params: {
          quotation: {
            customer_id: @customer.id,
            subject: "追加導入のご提案",
            quoted_by_name: "営業担当",
            quotation_date: "2026-04-11",
            expiration_date: "2026-04-30",
            remarks: "見積作成画面から登録",
            quotation_items_attributes: {
              "0" => {
                product_id: @product.id,
                quantity: 3,
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
    end

    quotation = Quotation.order(:id).last
    assert_redirected_to admin_quotation_path(quotation)

    get admin_quotation_path(quotation)
    assert_response :success

    get download_excel_admin_quotation_path(quotation)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.media_type
    assert_includes response.headers["Content-Disposition"], "#{quotation.quotation_number}.xlsx"
    assert_equal "PK", response.body.byteslice(0, 2)
    assert_includes zip_entry_content(response.body, "xl/worksheets/sheet1.xml"), quotation.quotation_number

    patch send_quotation_admin_quotation_path(quotation)
    assert_redirected_to admin_quotation_path(quotation)
    assert quotation.reload.sent?

    patch accept_quotation_admin_quotation_path(quotation)
    assert_redirected_to admin_quotation_path(quotation)
    assert quotation.reload.accepted?

    assert_difference("Order.count", 1) do
      post create_order_admin_quotation_path(quotation)
    end

    order = Order.order(:id).last
    assert_redirected_to admin_order_path(order)
    assert quotation.reload.converted?
    assert_equal quotation.id, order.quotation_id
    assert_equal 1, order.order_items.count
    assert_equal 3, order.order_items.first.quantity
    assert_equal 1000, order.order_items.first.unit_price.to_i

    get admin_order_path(order)
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

  test "payment can be created from invoice and auto reconciled" do
    invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: Date.new(2026, 5, 31),
      status: "issued",
      subtotal_amount: 2000,
      tax_amount: 200,
      total_amount: 2200,
      paid_amount: 0,
      balance_amount: 2200
    )
    invoice.invoice_items.create!(
      tenant: @tenant,
      description: "標準商品",
      quantity: 2,
      unit_price: 1000,
      amount: 2000,
      tax_category: "taxable_10"
    )

    get admin_invoice_path(invoice)
    assert_response :success
    assert_select "a", text: "この請求の入金を登録"

    get new_admin_payment_path(source_invoice_id: invoice.id)
    assert_response :success
    assert_select "input[name='source_invoice_id'][value='#{invoice.id}']", count: 1
    assert_select "input[name='payment[amount]'][value='2200.0'], input[name='payment[amount]'][value='2200']", count: 1

    assert_difference(["Payment.count", "PaymentAllocation.count"], 1) do
      post admin_payments_path, params: {
        source_invoice_id: invoice.id,
        payment: {
          customer_id: @customer.id,
          payment_date: "2026-05-20",
          amount: 2200,
          payment_method: "bank_transfer",
          bank_name: "請求連動銀行",
          account_name: "請求連動口座",
          reference_note: "請求から登録"
        }
      }
    end

    payment = Payment.order(:id).last
    assert_redirected_to admin_payment_path(payment)
    assert_equal invoice.id, payment.payment_allocations.last.invoice_id
    assert payment.reload.applied?
    assert invoice.reload.paid?
  end

  private

  def zip_entry_content(body, entry_name)
    content = nil

    Zip::InputStream.open(StringIO.new(body.b)) do |stream|
      while (entry = stream.get_next_entry)
        next unless entry.name == entry_name

        content = stream.read
        break
      end
    end

    content.to_s
  end
end
