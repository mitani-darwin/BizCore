require "test_helper"

class Imports::CustomerImportTest < ActiveSupport::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "得意先インポートテナント",
      code: "customer-import",
      subdomain: "customer-import",
      plan: "standard",
      status: "active",
      billing_email: "billing@customer-import.example.com"
    )
  end

  test "正常な CSV を取り込める" do
    csv = <<~CSV
      得意先コード,得意先名,ステータス(active/inactive),メール,電話番号,郵便番号,住所1,住所2,担当部署,担当者名,担当者メール
      C001,東京商事,active,info@tokyo.example.com,03-0000-1111,100-0001,東京都千代田区,,営業部,田中一郎,tanaka@tokyo.example.com
      C002,大阪産業,active,,,530-0001,大阪府大阪市北区,,,山田次郎,
    CSV

    result = Imports::CustomerImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 2, result.total
    assert_equal 2, result.succeeded
    assert_empty result.failed_rows

    c1 = @tenant.customers.find_by(code: "C001")
    assert_equal "東京商事", c1.name
    assert_equal "info@tokyo.example.com", c1.email
    assert_equal "田中一郎", c1.contact_person_name
  end

  test "既存の得意先コードは更新される" do
    @tenant.customers.create!(code: "C001", name: "旧社名", status: "active")

    csv = <<~CSV
      得意先コード,得意先名,ステータス(active/inactive),メール,電話番号,郵便番号,住所1,住所2,担当部署,担当者名,担当者メール
      C001,新社名,active,,,,,,,,
    CSV

    result = Imports::CustomerImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 1, result.succeeded
    assert_equal "新社名", @tenant.customers.find_by(code: "C001").name
  end

  test "得意先コードが空の行はエラー" do
    csv = <<~CSV
      得意先コード,得意先名,ステータス(active/inactive),メール,電話番号,郵便番号,住所1,住所2,担当部署,担当者名,担当者メール
      ,名前あり,active,,,,,,,,
    CSV

    result = Imports::CustomerImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 0, result.succeeded
    assert_equal 1, result.failed_rows.size
  end

  test "メール形式が不正な行はエラー" do
    csv = <<~CSV
      得意先コード,得意先名,ステータス(active/inactive),メール,電話番号,郵便番号,住所1,住所2,担当部署,担当者名,担当者メール
      C001,テスト得意先,active,invalid-email,,,,,,,,
    CSV

    result = Imports::CustomerImport.call(tenant: @tenant, csv_string: csv)

    assert_equal 0, result.succeeded
    assert_equal 1, result.failed_rows.size
  end
end
