require "test_helper"

class InvoiceTaxBreakdownTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "インボイステスト",
      code: "invoice-test",
      subdomain: "invoicetest",
      plan: "standard",
      status: "active",
      billing_email: "test@invoice.example.com"
    )
    @customer = @tenant.customers.create!(
      code: "C001",
      name: "テスト得意先",
      closing_day: 31,
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      invoice_delivery_method: "email"
    )
    @invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 6, 30),
      billing_period_from: Date.new(2026, 6, 1),
      billing_period_to: Date.new(2026, 6, 30),
      invoice_date: Date.new(2026, 6, 30),
      due_date: Date.new(2026, 7, 31)
    )
    @invoice.invoice_items.create!(tenant: @tenant, description: "商品A（10%）", quantity: 1, unit_price: 10000, tax_category: "taxable_10")
    @invoice.invoice_items.create!(tenant: @tenant, description: "商品B（8%）",  quantity: 2, unit_price: 5000,  tax_category: "taxable_8")
    @invoice.invoice_items.create!(tenant: @tenant, description: "商品C（非課税）", quantity: 1, unit_price: 3000, tax_category: "non_taxable")
    @invoice.recalculate_totals!
  end

  test "tax_breakdown は課税区分ごとに小計と税額を返す" do
    breakdown = @invoice.tax_breakdown

    assert_includes breakdown.keys, "taxable_10"
    assert_includes breakdown.keys, "taxable_8"
    refute_includes breakdown.keys, "non_taxable"

    assert_equal 10000, breakdown["taxable_10"][:subtotal]
    assert_equal 1000,  breakdown["taxable_10"][:tax]

    assert_equal 10000, breakdown["taxable_8"][:subtotal]
    assert_equal 800,   breakdown["taxable_8"][:tax]
  end

  test "qualified_invoice_issuer? は登録番号が未設定の場合 false を返す" do
    assert_not @tenant.qualified_invoice_issuer?
  end

  test "qualified_invoice_issuer? は正しい登録番号が設定されている場合 true を返す" do
    @tenant.update!(invoice_registration_number: "T1234567890123")
    assert @tenant.qualified_invoice_issuer?
  end

  test "登録番号のフォーマットバリデーション" do
    @tenant.invoice_registration_number = "1234567890123"
    assert_not @tenant.valid?

    @tenant.invoice_registration_number = "T123456789012"
    assert_not @tenant.valid?

    @tenant.invoice_registration_number = "T1234567890123"
    assert @tenant.valid?

    @tenant.invoice_registration_number = ""
    assert @tenant.valid?
  end
end
