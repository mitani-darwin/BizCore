require "zip"

require "test_helper"

class Admin::ProcurementFlowControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Procurement Tenant",
      code: "procurement-tenant",
      subdomain: "procurement",
      plan: "standard",
      status: "active",
      billing_email: "owner@procurement.example.com"
    )

    @owner = User.create!(
      tenant: @tenant,
      name: "Procurement Owner",
      email: "owner@procurement.example.com",
      password: "Password123!",
      password_confirmation: "Password123!",
      locale: "ja",
      time_zone: "Asia/Tokyo",
      is_owner: true
    )

    @supplier = @tenant.suppliers.create!(
      code: "S001",
      name: "標準仕入先",
      status: "active",
      email: "supplier@example.com",
      payment_method: "bank_transfer",
      payment_due_rule: "next_month_end",
      closing_day: 31
    )
    @product = @tenant.products.create!(
      code: "P010",
      name: "仕入対象商品",
      unit_name: "個",
      standard_price: 400,
      tax_category: "taxable_10",
      active: true
    )
    @warehouse = @tenant.warehouses.create!(
      code: "W010",
      name: "受入倉庫",
      active: true
    )
    @stock_item = @tenant.stock_items.create!(
      warehouse: @warehouse,
      product: @product,
      quantity_on_hand: 2,
      quantity_reserved: 0,
      safety_stock: 1
    )

    Permissions::Catalog.seed_admin!
    sign_in @owner
  end

  test "procurement management screens render" do
    get admin_suppliers_path
    assert_response :success

    get new_admin_supplier_path
    assert_response :success

    get admin_supplier_path(@supplier)
    assert_response :success
    assert_select "a[href='#{new_admin_purchase_order_path(supplier_id: @supplier.id)}']", text: "新規発注"

    get admin_purchase_orders_path
    assert_response :success

    get new_admin_purchase_order_path(supplier_id: @supplier.id)
    assert_response :success
    assert_select "select[name='purchase_order[supplier_id]'] option[selected='selected'][value='#{@supplier.id}']"
    assert_select "tbody[data-order-items-target='rows'] > tr[data-order-items-target='row']", count: 1
    assert_select "button[data-action='order-items#addRow']", text: "明細を追加"

    get admin_purchase_receipts_path
    assert_response :success

    get admin_purchase_adjustments_path
    assert_response :success

    get admin_purchase_bills_path
    assert_response :success

    get admin_purchase_bill_batches_path
    assert_response :success

    get admin_supplier_payments_path
    assert_response :success

    get new_admin_supplier_payment_path
    assert_response :success
  end

  test "procurement flow proceeds from purchase order to receipt return, billing, and payment reconciliation" do
    assert_difference(["PurchaseOrder.count", "PurchaseOrderItem.count"], 1) do
      post admin_purchase_orders_path, params: {
        purchase_order: {
          supplier_id: @supplier.id,
          warehouse_id: @warehouse.id,
          order_date: "2026-04-11",
          requested_delivery_date: "2026-04-15",
          ordered_by_name: "購買担当",
          remarks: "定期発注",
          purchase_order_items_attributes: {
            "0" => {
              product_id: @product.id,
              quantity: 5,
              unit_cost: 400
            },
            "1" => {
              product_id: "",
              quantity: "",
              unit_cost: ""
            }
          }
        }
      }
    end

    purchase_order = PurchaseOrder.order(:id).last
    assert_redirected_to admin_purchase_order_path(purchase_order)
    assert_equal "draft", purchase_order.status
    assert_equal @supplier.id, purchase_order.supplier_id

    get admin_purchase_order_path(purchase_order)
    assert_response :success
    assert_xlsx_download(
      download_excel_admin_purchase_order_path(purchase_order),
      filename: "#{purchase_order.purchase_order_number}.xlsx",
      includes: [purchase_order.purchase_order_number, purchase_order.supplier.name]
    )

    patch send_purchase_order_admin_purchase_order_path(purchase_order)
    assert_redirected_to admin_purchase_order_path(purchase_order)
    assert purchase_order.reload.sent?

    assert_difference(["PurchaseReceipt.count", "PurchaseReceiptItem.count", "StockMovement.count"], 1) do
      patch receive_items_admin_purchase_order_path(purchase_order), params: {
        received_on: "2026-04-12",
        received_by_name: "倉庫担当",
        remarks: "初回入荷",
        received_quantities: {
          purchase_order.purchase_order_items.first.id.to_s => "2"
        }
      }
    end

    first_receipt = PurchaseReceipt.order(:id).last
    assert_redirected_to admin_purchase_receipt_path(first_receipt)
    assert_equal 4, @stock_item.reload.quantity_on_hand
    assert_equal "partially_received", purchase_order.reload.status
    assert_equal "partially_received", purchase_order.purchase_order_items.first.reload.status
    assert_equal 3, purchase_order.purchase_order_items.first.remaining_quantity

    get admin_purchase_receipt_path(first_receipt)
    assert_response :success
    assert_xlsx_download(
      download_excel_admin_purchase_receipt_path(first_receipt),
      filename: "#{first_receipt.purchase_receipt_number}.xlsx",
      includes: [first_receipt.purchase_receipt_number, first_receipt.supplier.name]
    )

    assert_difference(["PurchaseReceipt.count", "PurchaseReceiptItem.count", "StockMovement.count"], 1) do
      patch receive_items_admin_purchase_order_path(purchase_order), params: {
        received_on: "2026-04-13",
        received_by_name: "倉庫担当",
        remarks: "残数入荷",
        received_quantities: {
          purchase_order.purchase_order_items.first.id.to_s => "3"
        }
      }
    end

    second_receipt = PurchaseReceipt.order(:id).last
    assert_redirected_to admin_purchase_receipt_path(second_receipt)
    assert_equal 7, @stock_item.reload.quantity_on_hand
    assert_equal "received", purchase_order.reload.status
    assert_equal "received", purchase_order.purchase_order_items.first.reload.status
    assert_equal 0, purchase_order.purchase_order_items.first.remaining_quantity

    get admin_purchase_receipts_path(q: second_receipt.purchase_receipt_number)
    assert_response :success
    assert_select "td", text: second_receipt.purchase_receipt_number

    assert_difference(["PurchaseAdjustment.count", "StockMovement.count"], 1) do
      post admin_purchase_adjustments_path, params: {
        purchase_adjustment: {
          purchase_receipt_id: second_receipt.id,
          adjustment_type: "purchase_return",
          purchase_receipt_item_id: second_receipt.purchase_receipt_items.first.id,
          adjustment_date: "2026-04-14",
          processed_by_name: "品質担当",
          reason: "破損返品",
          quantity: 1
        }
      }
    end

    return_adjustment = PurchaseAdjustment.order(:id).last
    assert_redirected_to admin_purchase_adjustment_path(return_adjustment)
    assert return_adjustment.purchase_return?
    assert_equal 6, @stock_item.reload.quantity_on_hand
    assert_equal "outbound", StockMovement.order(:id).last.movement_type
    assert_equal 2, second_receipt.purchase_receipt_items.first.reload.returnable_quantity

    assert_difference("PurchaseAdjustment.count", 1) do
      post admin_purchase_adjustments_path, params: {
        purchase_adjustment: {
          purchase_receipt_id: second_receipt.id,
          adjustment_type: "discount",
          adjustment_date: "2026-04-15",
          processed_by_name: "購買責任者",
          reason: "単価調整",
          amount: 200
        }
      }
    end

    discount_adjustment = PurchaseAdjustment.order(:id).last
    assert_redirected_to admin_purchase_adjustment_path(discount_adjustment)
    assert discount_adjustment.discount?
    assert_equal 1200, second_receipt.reload.total_amount.to_i
    assert_equal 400, second_receipt.total_return_amount.to_i
    assert_equal 200, second_receipt.total_discount_amount.to_i
    assert_equal 600, second_receipt.net_amount.to_i

    get admin_purchase_adjustment_path(discount_adjustment)
    assert_response :success

    get admin_purchase_adjustments_path(adjustment_type: "discount")
    assert_response :success
    assert_select "td", text: discount_adjustment.adjustment_number

    assert_difference(["PurchaseBillBatch.count", "PurchaseBill.count"], 1) do
      post issue_monthly_admin_purchase_bills_path, params: {
        billing_period_from: "2026-04-01",
        billing_period_to: "2026-04-30",
        closing_date: "2026-04-30",
        bill_date: "2026-04-30",
        default_due_date: "2026-05-31"
      }
    end

    purchase_bill_batch = PurchaseBillBatch.order(:id).last
    assert_redirected_to admin_purchase_bill_batch_path(purchase_bill_batch)

    get admin_purchase_bill_batch_path(purchase_bill_batch)
    assert_response :success

    purchase_bill = PurchaseBill.order(:id).last
    get admin_purchase_bill_path(purchase_bill)
    assert_response :success
    assert_select "a", text: "この請求の支払を登録"
    assert_xlsx_download(
      download_excel_admin_purchase_bill_path(purchase_bill),
      filename: "#{purchase_bill.bill_number}.xlsx",
      includes: [purchase_bill.bill_number, purchase_bill.supplier.name]
    )

    get new_admin_supplier_payment_path(source_purchase_bill_id: purchase_bill.id)
    assert_response :success
    assert_select "input[name='source_purchase_bill_id'][value='#{purchase_bill.id}']", count: 1
    assert_select "input[name='supplier_payment[amount]'][value='#{purchase_bill.outstanding_amount.to_i}.0'], input[name='supplier_payment[amount]'][value='#{purchase_bill.outstanding_amount.to_i}']", count: 1

    assert_difference(["SupplierPayment.count", "SupplierPaymentAllocation.count"], 1) do
      post admin_supplier_payments_path, params: {
        source_purchase_bill_id: purchase_bill.id,
        supplier_payment: {
          supplier_id: @supplier.id,
          payment_date: "2026-05-20",
          amount: purchase_bill.outstanding_amount.to_i,
          payment_method: "bank_transfer",
          bank_name: "テスト銀行",
          account_name: "買掛口座",
          reference_note: "仕入請求から登録"
        }
      }
    end

    supplier_payment = SupplierPayment.order(:id).last
    assert_redirected_to admin_supplier_payment_path(supplier_payment)
    assert_equal purchase_bill.id, supplier_payment.supplier_payment_allocations.last.purchase_bill_id
    assert supplier_payment.reload.applied?
    assert purchase_bill.reload.paid?

    get admin_supplier_payment_path(supplier_payment)
    assert_response :success
  end

  private

  def assert_xlsx_download(path, filename:, includes:)
    get path
    assert_response :success
    assert_equal Reports::BaseXlsx::MIME_TYPE, response.media_type
    assert_includes response.headers["Content-Disposition"], filename
    assert_equal "PK", response.body.byteslice(0, 2)

    sheet_xml = zip_entry_content(response.body, "xl/worksheets/sheet1.xml").force_encoding("UTF-8")
    Array(includes).each do |value|
      assert_includes sheet_xml, value
    end
  end

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
