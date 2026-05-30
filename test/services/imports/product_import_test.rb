require "test_helper"

class Imports::ProductImportTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "商品インポートテナント",
      code: "product-import",
      subdomain: "product-import",
      plan: "standard",
      status: "active",
      billing_email: "billing@product-import.example.com"
    )
  end

  test "正常な CSV を取り込める" do
    csv = <<~CSV
      商品コード,商品名,単位,標準単価,税区分(taxable_10/taxable_8/non_taxable),備考
      PRD001,テスト商品A,個,1000,taxable_10,備考A
      PRD002,有機野菜セット,箱,3500,taxable_8,
    CSV

    result = Imports::ProductImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 2, result.total
    assert_equal 2, result.succeeded
    assert_empty result.failed_rows

    p1 = @tenant.products.find_by(code: "PRD001")
    assert_equal "テスト商品A", p1.name
    assert_equal "個", p1.unit_name
    assert_in_delta 1000, p1.standard_price.to_f
    assert_equal "taxable_10", p1.tax_category

    p2 = @tenant.products.find_by(code: "PRD002")
    assert_equal "taxable_8", p2.tax_category
  end

  test "既存の商品コードは更新される" do
    @tenant.products.create!(code: "PRD001", name: "旧名前", unit_name: "個", standard_price: 500)

    csv = <<~CSV
      商品コード,商品名,単位,標準単価,税区分(taxable_10/taxable_8/non_taxable),備考
      PRD001,新しい名前,台,2000,taxable_10,
    CSV

    result = Imports::ProductImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 1, result.succeeded
    assert_equal "新しい名前", @tenant.products.find_by(code: "PRD001").name
  end

  test "商品コードが空の行はエラー" do
    csv = <<~CSV
      商品コード,商品名,単位,標準単価,税区分(taxable_10/taxable_8/non_taxable),備考
      ,名前あり,個,100,taxable_10,
    CSV

    result = Imports::ProductImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 0, result.succeeded
    assert_equal 1, result.failed_rows.size
  end

  test "template_csv がヘッダー行とサンプル行を含む" do
    csv_string = Imports::ProductImport.template_csv
    rows = CSV.parse(csv_string, headers: false)

    assert rows.first.include?("商品コード")
    assert rows.first.include?("商品名")
  end
end
