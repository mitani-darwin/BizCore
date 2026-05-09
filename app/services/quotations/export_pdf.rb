# 見積書 PDF 出力サービス。
# Quotations::ExportXlsx と同じデータを PDF 形式で出力する。
module Quotations
  class ExportPdf < Reports::BasePdf
    STATUS_LABELS = {
      "draft" => "下書き",
      "sent" => "提示済",
      "accepted" => "採用",
      "converted" => "注文変換済",
      "cancelled" => "取消"
    }.freeze
    DEFAULT_COLUMN_WIDTHS = [ 18, 28, 12, 14, 14, 16 ].freeze

    def initialize(quotation:, template: nil)
      @quotation = quotation
      @template = template
    end

    private

    attr_reader :quotation

    def document_title
      "見積書"
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
          [ "見積番号", quotation.quotation_number ],
          [ "状態", status_label ],
          [ "見積日", jp_date(quotation.quotation_date) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("customer_expiry")
        info_rows << [
          [ "得意先", quotation.customer.name ],
          [ "有効期限", jp_date(quotation.expiration_date) ],
          [ "社内担当者", quotation.quoted_by_name.presence || "-" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "得意先担当者", quotation.customer.primary_contact.presence || "-" ],
          [ "メール", quotation.customer.contact_person_email.presence || quotation.customer.email.presence || "-" ],
          [ "電話", quotation.customer.contact_person_tel.presence || quotation.customer.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "件名", quotation.subject.presence || "-") if row_visible?("subject")
      render_full_width_row(pdf, "備考", quotation.remarks.presence || "-") if row_visible?("remarks")

      render_section_title(pdf, "見積明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("product_code", "商品コード"),
        item_col_label("product_name", "商品名"),
        item_col_label("quantity", "数量"),
        item_col_label("unit_price", "単価"),
        item_col_label("tax_amount", "税額"),
        item_col_label("amount", "金額")
      ]
      item_rows = quotation.quotation_items.order(:line_no).map do |item|
        [
          item.product_code_snapshot,
          item.product_name_snapshot,
          item.quantity,
          item.unit_price.to_i,
          item.tax_amount.to_i,
          item.amount.to_i
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "小計", quotation.subtotal_amount.to_i, col_count: col_count)
      render_total_row(pdf, "税額", quotation.tax_amount.to_i, col_count: col_count)
      render_total_row(pdf, "合計", quotation.total_amount.to_i, col_count: col_count)
    end

    def status_label
      STATUS_LABELS.fetch(quotation.status.to_s, quotation.status.to_s)
    end
  end
end
