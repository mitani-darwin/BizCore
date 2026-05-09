# 請求書 PDF 出力サービス。
# Invoicing::ExportInvoiceXlsx と同じデータを PDF 形式で出力する。
module Invoicing
  class ExportInvoicePdf < Reports::BasePdf
    # XLSX サービスと同じ列幅比率を使用
    DEFAULT_COLUMN_WIDTHS = [ 24, 10, 12, 12, 12, 14 ].freeze

    def initialize(invoice:, template: nil)
      @invoice = invoice
      @template = template
    end

    private

    attr_reader :invoice

    def document_title
      "請求書"
    end

    def default_column_widths
      DEFAULT_COLUMN_WIDTHS
    end

    def build_pdf(pdf)
      render_company_header(pdf)
      render_title(pdf)

      # 固定行（常に表示）
      render_info_table(pdf, [
        [
          [ "請求番号", invoice.invoice_number ],
          [ "状態", invoice_status_label(invoice.status) ],
          [ "請求日", jp_date(invoice.invoice_date) ]
        ]
      ])

      # テンプレートで表示/非表示が制御される行
      info_rows = []
      if row_visible?("customer_payment")
        info_rows << [
          [ "得意先", invoice.customer.name ],
          [ "支払期日", jp_date(invoice.due_date) ],
          [ "請求締め", invoice.billing_batch&.batch_number || "-" ]
        ]
      end
      if row_visible?("delivery_terms")
        info_rows << [
          [ "送付方法", invoice_delivery_method_label(invoice.invoice_delivery_method_snapshot) ],
          [ "支払条件", payment_due_rule_label(invoice.payment_due_rule_snapshot) ],
          [ "締日", "#{jp_date(invoice.closing_date)} (#{invoice.closing_day_snapshot || "-"}日締め)" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "得意先担当者", invoice.customer.primary_contact.presence || "-" ],
          [ "メール", invoice.customer.contact_person_email.presence || invoice.customer.email.presence || "-" ],
          [ "電話", invoice.customer.contact_person_tel.presence || invoice.customer.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "請求期間", "#{jp_date(invoice.billing_period_from)} 〜 #{jp_date(invoice.billing_period_to)}") if row_visible?("billing_period")
      render_full_width_row(pdf, "請求先住所", invoice.customer.full_address.presence || "-") if row_visible?("address")
      render_full_width_row(pdf, "備考", invoice.remarks.presence || "-") if row_visible?("remarks")
      render_full_width_row(pdf, "再発行元", invoice.reissued_from.invoice_number) if invoice.reissued_from.present?

      render_section_title(pdf, "請求明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("description", "内容"),
        item_col_label("quantity", "数量"),
        item_col_label("unit_price", "単価"),
        item_col_label("tax_category", "税区分"),
        item_col_label("tax_amount", "税額"),
        item_col_label("amount", "金額")
      ]
      item_rows = invoice.invoice_items.map do |item|
        [
          item.description,
          item.quantity,
          item.unit_price.to_i,
          tax_category_label(item.tax_category),
          item.tax_amount.to_i,
          item.amount.to_i
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "小計", invoice.subtotal_amount.to_i, col_count: col_count)
      render_total_row(pdf, "税額", invoice.tax_amount.to_i, col_count: col_count)
      render_total_row(pdf, "合計", invoice.total_amount.to_i, col_count: col_count)
      render_total_row(pdf, "入金済", invoice.paid_amount.to_i, col_count: col_count)
      render_total_row(pdf, "残高", invoice.balance_amount.to_i, col_count: col_count)
    end
  end
end
