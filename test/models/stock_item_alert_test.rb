require "test_helper"

class StockItemAlertTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tenant = Tenant.create!(
      name: "在庫モデルテナント",
      code: "stock-model",
      subdomain: "stock-model",
      plan: "standard",
      status: "active",
      billing_email: "billing@stock-model.example.com"
    )
    @warehouse = @tenant.warehouses.create!(code: "WH-M", name: "モデルテスト倉庫")
  end

  def create_product(suffix)
    @tenant.products.create!(code: "PRD-#{suffix}", name: "商品#{suffix}", unit_name: "個", standard_price: 100)
  end

  def create_stock_item(product:, quantity_on_hand:, quantity_reserved: 0, safety_stock:)
    @tenant.stock_items.create!(
      warehouse: @warehouse,
      product: product,
      quantity_on_hand: quantity_on_hand,
      quantity_reserved: quantity_reserved,
      safety_stock: safety_stock
    )
  end

  # ── スコープのテスト ──────────────────────────────────────────────

  test "low_stock スコープ: 安全在庫以下（在庫 > 0）の品目を返す" do
    low_item  = create_stock_item(product: create_product("L1"), quantity_on_hand: 3, safety_stock: 5)
    ok_item   = create_stock_item(product: create_product("L2"), quantity_on_hand: 10, safety_stock: 5)
    zero_item = create_stock_item(product: create_product("L3"), quantity_on_hand: 0, safety_stock: 5)

    low_ids = @tenant.stock_items.low_stock.pluck(:id)
    assert_includes     low_ids, low_item.id,  "安全在庫割れ品目が含まれるべき"
    assert_not_includes low_ids, ok_item.id,   "正常品目は含まれないべき"
    assert_not_includes low_ids, zero_item.id, "在庫切れ品目は low_stock に含まれないべき"
  end

  test "out_of_stock スコープ: 利用可能在庫が 0 以下の品目を返す" do
    out_item = create_stock_item(product: create_product("O1"), quantity_on_hand: 0, safety_stock: 5)
    ok_item  = create_stock_item(product: create_product("O2"), quantity_on_hand: 10, safety_stock: 5)

    out_ids = @tenant.stock_items.out_of_stock.pluck(:id)
    assert_includes     out_ids, out_item.id
    assert_not_includes out_ids, ok_item.id
  end

  # ── adjust_on_hand! のアラートテスト ─────────────────────────────

  test "adjust_on_hand!: 減少で閾値を下回った場合に StockAlertJob がエンキューされる" do
    product = create_product("A1")
    item = create_stock_item(product: product, quantity_on_hand: 10, safety_stock: 5)
    assert_not item.low_stock?

    assert_enqueued_with(job: StockAlertJob) do
      item.adjust_on_hand!(-6) # 10 → 4、安全在庫 5 を下回る
    end
  end

  test "adjust_on_hand!: 増加の場合は StockAlertJob はエンキューされない" do
    product = create_product("A2")
    item = create_stock_item(product: product, quantity_on_hand: 3, safety_stock: 5)

    assert_no_enqueued_jobs(only: StockAlertJob) do
      item.adjust_on_hand!(+10)
    end
  end

  test "adjust_on_hand!: 既に低在庫状態からさらに減っても StockAlertJob はエンキューされない（スパム防止）" do
    product = create_product("A3")
    item = create_stock_item(product: product, quantity_on_hand: 3, safety_stock: 5)
    assert item.low_stock?

    assert_no_enqueued_jobs(only: StockAlertJob) do
      item.adjust_on_hand!(-1) # 元から低在庫、重複通知なし
    end
  end

  # ── reserve! のアラートテスト ────────────────────────────────────

  test "reserve!: 正常→在庫不足への閾値越えで StockAlertJob がエンキューされる" do
    product = create_product("R1")
    # available = 10 - 4 = 6 > 5 → 正常
    item = create_stock_item(product: product, quantity_on_hand: 10, quantity_reserved: 4, safety_stock: 5)
    assert_not item.low_stock?

    assert_enqueued_with(job: StockAlertJob) do
      item.reserve!(2) # available: 6 → 4 で閾値割れ
    end
  end

  test "reserve!: 既に低在庫状態では StockAlertJob はエンキューされない" do
    product = create_product("R2")
    # available = 7 - 4 = 3 < 5 → 既に低在庫
    item = create_stock_item(product: product, quantity_on_hand: 7, quantity_reserved: 4, safety_stock: 5)
    assert item.low_stock?

    assert_no_enqueued_jobs(only: StockAlertJob) do
      item.reserve!(1)
    end
  end

  # ── low_stock? / out_of_stock? のユニットテスト ──────────────────

  test "low_stock?: 利用可能在庫が安全在庫以下で true" do
    item = create_stock_item(product: create_product("P1"), quantity_on_hand: 3, safety_stock: 5)
    assert item.low_stock?
  end

  test "low_stock?: 利用可能在庫が安全在庫より多ければ false" do
    item = create_stock_item(product: create_product("P2"), quantity_on_hand: 10, safety_stock: 5)
    assert_not item.low_stock?
  end

  test "out_of_stock?: 利用可能在庫が 0 で true" do
    item = create_stock_item(product: create_product("P3"), quantity_on_hand: 0, safety_stock: 5)
    assert item.out_of_stock?
  end
end
