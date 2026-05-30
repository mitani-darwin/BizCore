require "test_helper"

class Purchases::ExportPurchaseOrderPdfTest < ActiveSupport::TestCase
  setup do
    # 日本語フォントがない環境（CI 等）ではスキップする。
    # フォントを用意する場合は PRAWN_JAPANESE_FONT_PATH 環境変数を設定してください。
    begin
      Reports::PdfFont.font_path
    rescue RuntimeError
      skip "日本語フォントが見つからないためスキップします"
    end
    @tenant = Tenant.create!(
      name: "PDF テストテナント",
      code: "pdf-test",
      subdomain: "pdf-test",
      plan: "standard",
      status: "active",
      billing_email: "billing@pdf-test.example.com"
    )

    @supplier = @tenant.suppliers.create!(
      code: "SUP-PDF-1",
      name: "PDFテスト仕入先",
      status: "active",
      email: "supplier@pdf-test.example.com",
      contact_person_name: "山田太郎",
      contact_person_email: "yamada@pdf-test.example.com",
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      closing_day: 31
    )

    @warehouse = @tenant.warehouses.create!(code: "WH-PDF", name: "PDF倉庫")

    @product = @tenant.products.create!(
      code: "PRD-PDF-1",
      name: "テスト商品A",
      unit_name: "個",
      standard_price: 1_500,
      tax_category: "taxable_10"
    )

    @purchase_order = @tenant.purchase_orders.create!(
      supplier: @supplier,
      warehouse: @warehouse,
      order_date: Date.new(2026, 6, 1),
      requested_delivery_date: Date.new(2026, 6, 15),
      ordered_by_name: "担当者名",
      status: "sent"
    )

    @purchase_order.purchase_order_items.create!(
      tenant: @tenant,
      product: @product,
      line_no: 1,
      quantity: 10,
      unit_cost: 1_500,
      amount: 15_000,
      status: "pending",
      product_code_snapshot: @product.code,
      product_name_snapshot: @product.name,
      unit_name_snapshot: @product.unit_name,
      tax_category_snapshot: @product.tax_category
    )
  end

  test "テンプレートなしで PDF バイナリが生成される" do
    result = Purchases::ExportPurchaseOrderPdf.call(purchase_order: @purchase_order)

    assert result.is_a?(String)
    assert result.start_with?("%PDF"), "PDF ヘッダーで始まっているべき"
    assert result.length > 1_000, "PDF サイズが想定より小さい"
  end

  test "テンプレートありで PDF バイナリが生成される" do
    template = DocumentTemplate.for_tenant_and_type(@tenant, "purchase_order")
    result = Purchases::ExportPurchaseOrderPdf.call(purchase_order: @purchase_order, template: template)

    assert result.is_a?(String)
    assert result.start_with?("%PDF")
  end

  test "明細が複数あっても PDF が生成される" do
    product2 = @tenant.products.create!(
      code: "PRD-PDF-2",
      name: "テスト商品B",
      unit_name: "箱",
      standard_price: 3_000,
      tax_category: "taxable_8"
    )
    @purchase_order.purchase_order_items.create!(
      tenant: @tenant,
      product: product2,
      line_no: 2,
      quantity: 5,
      unit_cost: 3_000,
      amount: 15_000,
      status: "pending",
      product_code_snapshot: product2.code,
      product_name_snapshot: product2.name,
      unit_name_snapshot: product2.unit_name,
      tax_category_snapshot: product2.tax_category
    )

    result = Purchases::ExportPurchaseOrderPdf.call(purchase_order: @purchase_order)

    assert result.start_with?("%PDF")
  end

  test "明細なしでも PDF が生成される" do
    @purchase_order.purchase_order_items.delete_all

    assert_nothing_raised do
      result = Purchases::ExportPurchaseOrderPdf.call(purchase_order: @purchase_order)
      assert result.start_with?("%PDF")
    end
  end
end
