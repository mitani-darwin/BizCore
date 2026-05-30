require "test_helper"

class InvoiceMailerTest < ActionMailer::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "請求通知テナント",
      code: "invoice-notif",
      subdomain: "invoice-notif",
      plan: "standard",
      status: "active",
      billing_email: "billing@invoice-notif.example.com"
    )

    @customer = @tenant.customers.create!(
      code: "CUST-INV-1",
      name: "テスト得意先",
      status: "active",
      email: "customer@example.com"
    )

    @invoice = @tenant.invoices.create!(
      customer: @customer,
      closing_date: Date.new(2026, 6, 30),
      billing_period_from: Date.new(2026, 6, 1),
      billing_period_to: Date.new(2026, 6, 30),
      invoice_date: Date.new(2026, 7, 1),
      due_date: Date.new(2026, 7, 31),
      status: "issued",
      subtotal_amount: 100_000,
      tax_amount: 10_000,
      total_amount: 110_000,
      paid_amount: 0,
      balance_amount: 110_000
    )
  end

  test "invoice_issued: 件名・宛先が正しい" do
    mail = InvoiceMailer.invoice_issued(invoice: @invoice)

    assert_equal [ "customer@example.com" ], mail.to
    assert_match @invoice.invoice_number, mail.subject
    assert_match "請求書を発行しました", mail.subject
  end

  test "invoice_issued: テキスト・HTML 両方のパートが存在する" do
    mail = InvoiceMailer.invoice_issued(invoice: @invoice)

    assert mail.multipart?
    assert mail.parts.any? { |p| p.content_type.include?("text/plain") }
    assert mail.parts.any? { |p| p.content_type.include?("text/html") }
  end

  test "invoice_issued: 本文に請求金額・支払期日が含まれる" do
    mail = InvoiceMailer.invoice_issued(invoice: @invoice)

    text_body = mail.parts.find { |p| p.content_type.include?("text/plain") }&.decoded
    assert_match "110,000", text_body
    assert_match "2026/07/31", text_body
  end

  test "invoice_issued: 本文に請求期間が含まれる" do
    mail = InvoiceMailer.invoice_issued(invoice: @invoice)

    text_body = mail.parts.find { |p| p.content_type.include?("text/plain") }&.decoded
    assert_match "2026/06/01", text_body
    assert_match "2026/06/30", text_body
  end
end
