require "test_helper"

class OrderingWorkflowTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "Ordering Tenant",
      code: "ordering-tenant",
      subdomain: "ordering",
      plan: "standard",
      status: "active",
      billing_email: "owner@ordering.example.com"
    )

    @customer = Customer.create!(
      tenant: @tenant,
      code: "CUST-001",
      name: "Acme Customer",
      email: "buyer@example.com",
      closing_day: 31,
      payment_due_rule: "next_month_end",
      payment_method: "bank_transfer",
      invoice_delivery_method: "email"
    )

    @product = Product.create!(
      tenant: @tenant,
      code: "PROD-001",
      name: "標準商品",
      unit_name: "個",
      standard_price: 1000,
      tax_category: "taxable_10"
    )

    @warehouse = Warehouse.create!(
      tenant: @tenant,
      code: "WH-001",
      name: "本社倉庫"
    )

    @stock_item = StockItem.create!(
      tenant: @tenant,
      warehouse: @warehouse,
      product: @product,
      quantity_on_hand: 10,
      quantity_reserved: 0
    )
  end

  test "send order marks the order as sent" do
    order = create_order(quantity: 3)
    sent_at = Time.find_zone!("Asia/Tokyo").parse("2026-04-11 10:00:00")

    Orders::SendOrder.call(order: order, sent_at: sent_at)

    assert order.reload.sent?
    assert_equal sent_at, order.sent_at
  end

  test "reserve order secures stock after acceptance" do
    order = create_order(quantity: 3)
    order.mark_as_sent!
    order.mark_as_accepted!
    allocated_at = Time.find_zone!("Asia/Tokyo").parse("2026-04-11 11:00:00")

    Inventory::ReserveOrder.call(order: order, warehouse: @warehouse, allocated_at: allocated_at)

    item = order.order_items.first.reload
    assert order.reload.allocated?
    assert_equal 1, item.stock_allocations.count
    assert_equal 3, item.allocated_quantity
    assert_equal 3, @stock_item.reload.quantity_reserved
  end

  test "issue delivery consumes reserved stock and creates delivery note" do
    order = create_order(quantity: 3)
    order.mark_as_sent!
    order.mark_as_accepted!
    Inventory::ReserveOrder.call(order: order, warehouse: @warehouse)

    delivery = Deliveries::IssueFromOrder.call(order: order, delivery_date: Date.new(2026, 4, 12))

    assert delivery.persisted?
    assert_equal 1, delivery.delivery_items.count
    assert_equal 7, @stock_item.reload.quantity_on_hand
    assert_equal 0, @stock_item.reload.quantity_reserved
    assert_equal 1, StockMovement.count
    assert order.reload.delivered?
  end

  test "monthly billing creates invoices from delivered items once" do
    order = create_order(quantity: 3)
    order.mark_as_sent!
    order.mark_as_accepted!
    Inventory::ReserveOrder.call(order: order, warehouse: @warehouse)
    delivery = Deliveries::IssueFromOrder.call(order: order, delivery_date: Date.new(2026, 4, 12))

    batch = Invoicing::IssueMonthlyInvoices.call(
      tenant: @tenant,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      default_due_date: Date.new(2026, 5, 31)
    )

    invoice = batch.invoices.first
    assert_equal 1, batch.invoices.size
    assert_equal 1, batch.invoice_count
    assert_equal BigDecimal("3000"), invoice.subtotal_amount
    assert_equal BigDecimal("300"), invoice.tax_amount
    assert_equal BigDecimal("3300"), invoice.total_amount
    assert_equal Date.new(2026, 5, 31), invoice.due_date
    assert delivery.reload.billed?
    assert order.reload.billed?

    assert_raises(Invoicing::IssueMonthlyInvoices::AlreadyClosedError) do
      Invoicing::IssueMonthlyInvoices.call(
        tenant: @tenant,
        closing_date: Date.new(2026, 4, 30),
        billing_period_from: Date.new(2026, 4, 1),
        billing_period_to: Date.new(2026, 4, 30),
        invoice_date: Date.new(2026, 4, 30),
        default_due_date: Date.new(2026, 5, 31)
      )
    end
  end

  test "cancel and reissue invoice preserves billing history" do
    order = create_order(quantity: 2)
    order.mark_as_sent!
    order.mark_as_accepted!
    Inventory::ReserveOrder.call(order: order, warehouse: @warehouse)
    delivery = Deliveries::IssueFromOrder.call(order: order, delivery_date: Date.new(2026, 4, 12))

    batch = Invoicing::IssueMonthlyInvoices.call(
      tenant: @tenant,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      default_due_date: Date.new(2026, 5, 31)
    )
    invoice = batch.invoices.first

    Invoicing::CancelInvoice.call(invoice: invoice)

    assert invoice.reload.cancelled?
    assert delivery.reload.issued?
    assert order.reload.delivered?

    reissued = Invoicing::ReissueInvoice.call(invoice: invoice, invoice_date: Date.new(2026, 5, 1))

    assert reissued.persisted?
    assert_equal invoice.id, reissued.reissued_from_id
    assert reissued.issued?
    assert delivery.reload.billed?
    assert order.reload.billed?
  end

  test "cancelled billing batch can be rerun for the same closing period" do
    order = create_order(quantity: 1)
    order.mark_as_sent!
    order.mark_as_accepted!
    Inventory::ReserveOrder.call(order: order, warehouse: @warehouse)
    Deliveries::IssueFromOrder.call(order: order, delivery_date: Date.new(2026, 4, 12))

    batch = Invoicing::IssueMonthlyInvoices.call(
      tenant: @tenant,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      default_due_date: Date.new(2026, 5, 31)
    )

    Invoicing::CancelBillingBatch.call(billing_batch: batch)
    rerun = Invoicing::IssueMonthlyInvoices.call(
      tenant: @tenant,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 5, 1),
      default_due_date: Date.new(2026, 5, 31)
    )

    assert batch.reload.cancelled?
    assert rerun.persisted?
    assert_equal 1, rerun.invoice_count
  end

  test "payment reconciliation allocates money to invoices" do
    invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 4, 30),
      billing_period_from: Date.new(2026, 4, 1),
      billing_period_to: Date.new(2026, 4, 30),
      invoice_date: Date.new(2026, 4, 30),
      due_date: Date.new(2026, 5, 31)
    )
    invoice.invoice_items.create!(
      tenant: @tenant,
      description: "標準商品",
      quantity: 3,
      unit_price: 1000,
      tax_category: "taxable_10"
    )
    invoice.recalculate_totals!

    payment = @tenant.payments.create!(
      customer: @customer,
      payment_date: Date.new(2026, 5, 20),
      amount: 3300,
      payment_method: "bank_transfer"
    )

    Payments::ReconcilePayment.call(payment: payment, allocations: [{ invoice: invoice, amount: 3300 }])

    assert_equal 1, payment.payment_allocations.count
    assert payment.reload.applied?
    assert invoice.reload.paid?
    assert_equal BigDecimal("0"), invoice.balance_amount
  end

  private

  def create_order(quantity:)
    order = @tenant.orders.create!(
      customer: @customer,
      order_date: Date.new(2026, 4, 11),
      requested_delivery_date: Date.new(2026, 4, 12),
      ordered_by_name: "Buyer Person",
      delivery_address: "東京都港区1-2-3"
    )

    order.order_items.create!(
      tenant: @tenant,
      product: @product,
      quantity: quantity,
      unit_price: @product.standard_price
    )

    order
  end
end
