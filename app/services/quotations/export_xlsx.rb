module Quotations
  class ExportXlsx < Reports::BaseXlsx
    STATUS_LABELS = {
      "draft" => "下書き",
      "sent" => "提示済",
      "accepted" => "採用",
      "converted" => "注文変換済",
      "cancelled" => "取消"
    }.freeze
    COLUMN_WIDTHS = [ 18, 28, 12, 14, 14, 16 ].freeze

    def initialize(quotation:, template: nil)
      @quotation = quotation
      @template = template
    end

    private

    attr_reader :quotation

    def document_title
      "見積書"
    end

    def document_number
      quotation.quotation_number
    end

    def document_timestamp
      quotation.updated_at || quotation.created_at
    end

    def worksheet_name
      base = quotation.customer.name.to_s.gsub(/[\\\/\?\*\[\]:]/, "_")
      base = document_title if base.blank?
      base.first(31)
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("見積番号", quotation.quotation_number, "状態", status_label, "見積日", jp_date(quotation.quotation_date))
      rows << label_value_row("得意先", quotation.customer.name, "有効期限", jp_date(quotation.expiration_date), "社内担当者", quotation.quoted_by_name.presence || "-") if row_visible?("customer_expiry")
      rows << full_width_value_row("件名", quotation.subject.presence || "-", columns: column_widths.size) if row_visible?("subject")
      rows << label_value_row("得意先担当者", quotation.customer.primary_contact.presence || "-", "メール", quotation.customer.contact_person_email.presence || quotation.customer.email.presence || "-", "電話", quotation.customer.contact_person_tel.presence || quotation.customer.tel.presence || "-") if row_visible?("contact_info")
      rows << full_width_value_row("備考", quotation.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << blank_row
      rows << section_row("見積明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("product_code", "商品コード")),
        header_cell(item_col_label("product_name", "商品名")),
        header_cell(item_col_label("quantity", "数量")),
        header_cell(item_col_label("unit_price", "単価")),
        header_cell(item_col_label("tax_amount", "税額")),
        header_cell(item_col_label("amount", "金額"))
      ]

      quotation.quotation_items.order(:line_no).each do |item|
        rows << [
          body_cell(item.product_code_snapshot),
          body_cell(item.product_name_snapshot),
          number_cell(item.quantity),
          number_cell(item.unit_price.to_i),
          number_cell(item.tax_amount.to_i),
          number_cell(item.amount.to_i)
        ]
      end

      rows << total_row("小計", quotation.subtotal_amount.to_i, leading_blank_columns: 4)
      rows << total_row("税額", quotation.tax_amount.to_i, leading_blank_columns: 4)
      rows << total_row("合計", quotation.total_amount.to_i, leading_blank_columns: 4)
      rows
    end

    def status_label
      STATUS_LABELS.fetch(quotation.status.to_s, quotation.status.to_s)
    end
  end
end
