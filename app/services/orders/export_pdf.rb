# 注文書 PDF 出力サービス。
# Orders::ExportXlsx と同じデータを PDF 形式で出力する。
module Orders
  class ExportPdf < Reports::BasePdf
    DEFAULT_COLUMN_WIDTHS = [ 14, 26, 10, 12, 14, 10, 10, 14 ].freeze

    def initialize(order:, template: nil)
      @order = order
      @template = template
    end

    private

    attr_reader :order

    def document_title
      "注文書"
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
          [ "注文番号", order.order_number ],
          [ "状態", order_status_label(order.status) ],
          [ "注文日", jp_date(order.order_date) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("customer_delivery")
        info_rows << [
          [ "得意先", order.customer.name ],
          [ "希望納期", jp_date(order.requested_delivery_date) ],
          [ "先方担当者", order.ordered_by_name.presence || "-" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "得意先担当者", order.customer.primary_contact.presence || "-" ],
          [ "メール", order.customer.contact_person_email.presence || order.customer.email.presence || "-" ],
          [ "電話", order.customer.contact_person_tel.presence || order.customer.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "納品先住所", order.delivery_address.presence || "-") if row_visible?("delivery_address")
      render_full_width_row(pdf, "備考", order.remarks.presence || "-") if row_visible?("remarks")
      render_full_width_row(pdf, "元見積", order.quotation&.quotation_number || "-") if row_visible?("source_quotation")

      render_section_title(pdf, "注文明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("product_code", "商品コード"),
        item_col_label("product_name", "商品名"),
        item_col_label("quantity", "数量"),
        item_col_label("unit_price", "単価"),
        item_col_label("amount", "金額"),
        item_col_label("allocated", "引当"),
        item_col_label("delivered", "納品"),
        item_col_label("status", "状態")
      ]
      item_rows = order.order_items.order(:line_no).map do |item|
        [
          item.product_code_snapshot,
          item.product_name_snapshot,
          item.quantity,
          item.unit_price.to_i,
          item.amount.to_i,
          item.allocated_quantity,
          item.delivered_quantity,
          order_item_status_label(item.status)
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "合計", order.total_amount.to_i, col_count: col_count)
    end
  end
end
