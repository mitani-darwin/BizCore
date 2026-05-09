# 発注書 PDF 出力サービス。
# Purchases::ExportPurchaseOrderXlsx と同じデータを PDF 形式で出力する。
module Purchases
  class ExportPurchaseOrderPdf < Reports::BasePdf
    DEFAULT_COLUMN_WIDTHS = [ 14, 24, 10, 10, 10, 12, 14, 14 ].freeze

    def initialize(purchase_order:, template: nil)
      @purchase_order = purchase_order
      @template = template
    end

    private

    attr_reader :purchase_order

    def document_title
      "発注書"
    end

    def default_column_widths
      DEFAULT_COLUMN_WIDTHS
    end

    def build_pdf(pdf)
      render_company_header(pdf)
      render_title(pdf)

      # 固定行
      render_info_table(pdf, [
        [
          [ "発注番号", purchase_order.purchase_order_number ],
          [ "状態", purchase_order_status_label(purchase_order.status) ],
          [ "発注日", jp_date(purchase_order.order_date) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("supplier_delivery")
        info_rows << [
          [ "仕入先", purchase_order.supplier.name ],
          [ "希望納期", jp_date(purchase_order.requested_delivery_date) ],
          [ "発注担当者", purchase_order.ordered_by_name.presence || "-" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "仕入先担当者", purchase_order.supplier.primary_contact.presence || "-" ],
          [ "メール", purchase_order.supplier.contact_person_email.presence || purchase_order.supplier.email.presence || "-" ],
          [ "電話", purchase_order.supplier.contact_person_tel.presence || purchase_order.supplier.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "入荷倉庫", purchase_order.warehouse.name) if row_visible?("warehouse")
      render_full_width_row(pdf, "備考", purchase_order.remarks.presence || "-") if row_visible?("remarks")

      render_section_title(pdf, "発注明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("product_code", "商品コード"),
        item_col_label("product_name", "商品名"),
        item_col_label("quantity", "発注数量"),
        item_col_label("received", "入荷済"),
        item_col_label("remaining", "残数量"),
        item_col_label("unit_cost", "単価"),
        item_col_label("amount", "金額"),
        item_col_label("status", "状態")
      ]
      item_rows = purchase_order.purchase_order_items.order(:line_no).map do |item|
        [
          item.product_code_snapshot,
          item.product_name_snapshot,
          item.quantity,
          item.received_quantity,
          item.remaining_quantity,
          item.unit_cost.to_i,
          item.amount.to_i,
          purchase_order_item_status_label(item.status)
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "合計", purchase_order.total_amount.to_i, col_count: col_count)
      render_total_row(pdf, "返品合計", purchase_order.total_return_amount.to_i, col_count: col_count)
      render_total_row(pdf, "値引合計", purchase_order.total_discount_amount.to_i, col_count: col_count)
    end
  end
end
