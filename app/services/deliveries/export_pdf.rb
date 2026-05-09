# 納品書 PDF 出力サービス。
# Deliveries::ExportXlsx と同じデータを PDF 形式で出力する。
module Deliveries
  class ExportPdf < Reports::BasePdf
    DEFAULT_COLUMN_WIDTHS = [ 14, 26, 10, 12, 12, 14 ].freeze

    def initialize(delivery:, template: nil)
      @delivery = delivery
      @template = template
    end

    private

    attr_reader :delivery

    def document_title
      "納品書"
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
          [ "納品番号", delivery.delivery_number ],
          [ "状態", delivery_status_label(delivery.status) ],
          [ "納品日", jp_date(delivery.delivery_date) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("customer_order")
        info_rows << [
          [ "得意先", delivery.customer.name ],
          [ "注文番号", delivery.order.order_number ],
          [ "発行日時", delivery.issued_at.present? ? delivery.issued_at.strftime("%Y/%m/%d %H:%M") : "-" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "得意先担当者", delivery.customer.primary_contact.presence || "-" ],
          [ "メール", delivery.customer.contact_person_email.presence || delivery.customer.email.presence || "-" ],
          [ "電話", delivery.customer.contact_person_tel.presence || delivery.customer.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "納品先住所", delivery.delivery_address.presence || "-") if row_visible?("delivery_address")
      render_full_width_row(pdf, "備考", delivery.remarks.presence || "-") if row_visible?("remarks")

      render_section_title(pdf, "納品明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("product_code", "商品コード"),
        item_col_label("product_name", "商品名"),
        item_col_label("quantity", "数量"),
        item_col_label("unit_price", "単価"),
        item_col_label("tax_category", "税区分"),
        item_col_label("amount", "金額")
      ]
      item_rows = delivery.delivery_items.map do |item|
        [
          item.product_code_snapshot,
          item.product_name_snapshot,
          item.delivered_quantity,
          item.unit_price.to_i,
          tax_category_label(item.tax_category),
          item.amount.to_i
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "合計", delivery.total_amount.to_i, col_count: col_count)
    end
  end
end
