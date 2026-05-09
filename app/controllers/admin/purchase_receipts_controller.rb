module Admin
  class PurchaseReceiptsController < BaseController
    before_action :set_purchase_receipt, only: [ :show, :download_excel, :download_pdf ]

    def index
      @filters = {
        q: search_keyword,
        supplier_id: search_supplier_id
      }
      @supplier_filter_options = current_tenant.suppliers.ordered_for_admin
      @purchase_receipts = current_tenant.purchase_receipts
                                         .includes(:supplier, :warehouse, :purchase_order)
                                         .search(search_keyword)
                                         .with_supplier(search_supplier_id)
                                         .ordered_for_admin
      @summary = {
        count: @purchase_receipts.size,
        today_count: @purchase_receipts.count { |receipt| receipt.received_on == Date.current },
        amount_total: @purchase_receipts.sum(&:total_amount)
      }
    end

    def show
      @purchase_adjustments = @purchase_receipt.purchase_adjustments.ordered_for_admin
      @returnable_receipt_items = @purchase_receipt.purchase_receipt_items.select { |item| item.returnable_quantity.positive? }
    end

    def download_excel
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "purchase_receipt")
      send_data(
        Purchases::ExportPurchaseReceiptXlsx.call(purchase_receipt: @purchase_receipt, template: template),
        filename: "#{@purchase_receipt.purchase_receipt_number}.xlsx",
        type: Reports::BaseXlsx::MIME_TYPE,
        disposition: :attachment
      )
    end

    def download_pdf
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "purchase_receipt")
      send_data(
        Purchases::ExportPurchaseReceiptPdf.call(purchase_receipt: @purchase_receipt, template: template),
        filename: "#{@purchase_receipt.purchase_receipt_number}.pdf",
        type: Reports::BasePdf::MIME_TYPE,
        disposition: :attachment
      )
    end

    private

    def set_purchase_receipt
      @purchase_receipt = current_tenant.purchase_receipts.includes(:supplier, :warehouse, :purchase_order, purchase_adjustments: :purchase_receipt_item, purchase_receipt_items: [ :product, :purchase_adjustments ]).find_by(id: params[:id])
      return if @purchase_receipt

      render_not_found and return false
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_supplier_id
      supplier = current_tenant.suppliers.find_by(id: params[:supplier_id])
      supplier&.id
    end
  end
end
