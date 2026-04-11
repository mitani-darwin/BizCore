require "test_helper"

class Admin::InventoryManagementControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Inventory Tenant",
      code: "inventory-tenant",
      subdomain: "inventory",
      plan: "standard",
      status: "active",
      billing_email: "owner@inventory.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Inventory Owner",
      email: "owner@inventory.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @product = @tenant.products.create!(
      code: "P100",
      name: "在庫対象商品",
      unit_name: "個",
      standard_price: 1000,
      tax_category: "taxable_10",
      active: true
    )
    @warehouse = @tenant.warehouses.create!(
      code: "W100",
      name: "中央倉庫",
      active: true
    )
    @stock_item = @tenant.stock_items.create!(
      warehouse: @warehouse,
      product: @product,
      quantity_on_hand: 10,
      quantity_reserved: 0,
      safety_stock: 3
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "inventory management screens render" do
    get admin_stock_items_path
    assert_response :success

    get admin_stock_item_path(@stock_item)
    assert_response :success

    get admin_stock_movements_path
    assert_response :success

    get new_admin_stock_movement_path(stock_item_id: @stock_item.id)
    assert_response :success

    get admin_stock_counts_path
    assert_response :success

    get new_admin_stock_count_path(stock_item_id: @stock_item.id)
    assert_response :success
  end

  test "inventory management handles inbound and stock count adjustments" do
    assert_difference("StockMovement.count", 1) do
      post admin_stock_movements_path, params: {
        stock_movement: {
          warehouse_id: @warehouse.id,
          product_id: @product.id,
          movement_type: "inbound",
          quantity: 5,
          occurred_on: "2026-04-11",
          note: "仕入入庫"
        }
      }
    end

    assert_redirected_to admin_stock_movement_path(StockMovement.order(:id).last)
    assert_equal 15, @stock_item.reload.quantity_on_hand
    assert_equal "inbound", StockMovement.order(:id).last.movement_type

    assert_difference(["StockCount.count", "StockMovement.count"], 1) do
      post admin_stock_counts_path, params: {
        stock_count: {
          stock_item_id: @stock_item.id,
          counted_quantity: 2,
          counted_at: "2026-04-12T09:00",
          note: "月次棚卸"
        }
      }
    end

    assert_redirected_to admin_stock_item_path(@stock_item)
    assert_equal 2, @stock_item.reload.quantity_on_hand
    assert @stock_item.low_stock?

    stock_count = StockCount.order(:id).last
    movement = StockMovement.order(:id).last

    assert_equal -13, stock_count.adjustment_quantity
    assert_equal "adjustment_decrease", movement.movement_type
    assert_equal 13, movement.quantity
  end
end
