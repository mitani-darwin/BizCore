module Invoicing
  class ExportInvoiceXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 24, 10, 12, 12, 12, 14 ].freeze

    def initialize(invoice:, template: nil)
      @invoice = invoice
      @template = template
    end

    private

    attr_reader :invoice

    def document_title
      "請求書"
    end

    def document_number
      invoice.invoice_number
    end

    def document_timestamp
      invoice.updated_at || invoice.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{invoice.invoice_number}")
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("請求番号", invoice.invoice_number, "状態", invoice_status_label(invoice.status), "請求日", jp_date(invoice.invoice_date))
      rows << label_value_row("得意先", invoice.customer.name, "支払期日", jp_date(invoice.due_date), "請求締め", invoice.billing_batch&.batch_number || "-") if row_visible?("customer_payment")
      rows << label_value_row("請求送付方法", invoice_delivery_method_label(invoice.invoice_delivery_method_snapshot), "支払条件", payment_due_rule_label(invoice.payment_due_rule_snapshot), "締日", "#{jp_date(invoice.closing_date)} (#{invoice.closing_day_snapshot || "-"}日締め)") if row_visible?("delivery_terms")
      rows << label_value_row("得意先担当者", invoice.customer.primary_contact.presence || "-", "メール", invoice.customer.contact_person_email.presence || invoice.customer.email.presence || "-", "電話", invoice.customer.contact_person_tel.presence || invoice.customer.tel.presence || "-") if row_visible?("contact_info")
      rows << full_width_value_row("請求期間", "#{jp_date(invoice.billing_period_from)} 〜 #{jp_date(invoice.billing_period_to)}", columns: column_widths.size) if row_visible?("billing_period")
      rows << full_width_value_row("請求先住所", invoice.customer.full_address.presence || "-", columns: column_widths.size) if row_visible?("address")
      rows << full_width_value_row("備考", invoice.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << full_width_value_row("再発行元", invoice.reissued_from&.invoice_number || "-", columns: column_widths.size) if invoice.reissued_from.present?
      rows << blank_row
      rows << section_row("請求明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("description", "内容")),
        header_cell(item_col_label("quantity", "数量")),
        header_cell(item_col_label("unit_price", "単価")),
        header_cell(item_col_label("tax_category", "税区分")),
        header_cell(item_col_label("tax_amount", "税額")),
        header_cell(item_col_label("amount", "金額"))
      ]

      invoice.invoice_items.each do |item|
        rows << [
          body_cell(item.description),
          number_cell(item.quantity),
          number_cell(item.unit_price.to_i),
          body_cell(tax_category_label(item.tax_category)),
          number_cell(item.tax_amount.to_i),
          number_cell(item.amount.to_i)
        ]
      end

      rows << total_row("小計", invoice.subtotal_amount.to_i, leading_blank_columns: 4)
      rows << total_row("税額", invoice.tax_amount.to_i, leading_blank_columns: 4)
      rows << total_row("合計", invoice.total_amount.to_i, leading_blank_columns: 4)
      rows << total_row("入金済", invoice.paid_amount.to_i, leading_blank_columns: 4)
      rows << total_row("残高", invoice.balance_amount.to_i, leading_blank_columns: 4)
      rows
    end
  end
end
