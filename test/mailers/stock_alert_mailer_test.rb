require "test_helper"

class StockAlertMailerTest < ActionMailer::TestCase
  setup do
    @tenant = Tenant.create!(
      name: "在庫アラートテナント",
      code: "stock-alert",
      subdomain: "stock-alert",
      plan: "standard",
      status: "active",
      billing_email: "billing@stock-alert.example.com"
    )

    @warehouse = @tenant.warehouses.create!(code: "WH-A", name: "東京倉庫")

    @product = @tenant.products.create!(
      code: "PRD-A",
      name: "テスト商品",
      unit_name: "個",
      standard_price: 1_000
    )

    @stock_item = @tenant.stock_items.create!(
      warehouse: @warehouse,
      product: @product,
      quantity_on_hand: 3,
      quantity_reserved: 0,
      safety_stock: 5
    )

    @recipient = User.create!(
      tenant: @tenant,
      name: "担当者",
      email: "manager@stock-alert.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      is_owner: true
    )
  end

  test "low_stock_alert: 件名・宛先が正しい（在庫不足）" do
    mail = StockAlertMailer.low_stock_alert(stock_item: @stock_item, recipient: @recipient)

    assert_equal [ "manager@stock-alert.example.com" ], mail.to
    assert_match "在庫不足", mail.subject
    assert_match "テスト商品", mail.subject
    assert_match "東京倉庫", mail.subject
  end

  test "low_stock_alert: 件名に【在庫切れ】が含まれる場合" do
    @stock_item.update!(quantity_on_hand: 0)
    mail = StockAlertMailer.low_stock_alert(stock_item: @stock_item, recipient: @recipient)

    assert_match "在庫切れ", mail.subject
  end

  test "low_stock_alert: 本文に在庫数・安全在庫が含まれる" do
    mail = StockAlertMailer.low_stock_alert(stock_item: @stock_item, recipient: @recipient)
    text_body = mail.parts.find { |p| p.content_type.include?("text/plain") }&.decoded

    assert_match "3", text_body        # available_quantity
    assert_match "5", text_body        # safety_stock
    assert_match "テスト商品", text_body
    assert_match "東京倉庫", text_body
  end

  test "low_stock_alert: HTML・テキスト両パートが存在する" do
    mail = StockAlertMailer.low_stock_alert(stock_item: @stock_item, recipient: @recipient)

    assert mail.multipart?
    assert mail.parts.any? { |p| p.content_type.include?("text/plain") }
    assert mail.parts.any? { |p| p.content_type.include?("text/html") }
  end
end
