module Orders
  class ExportXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 14, 26, 10, 12, 14, 10, 10, 14 ].freeze

    def initialize(order:, template: nil)
      @order = order
      @template = template
    end

    private

    attr_reader :order

    def document_title
      "注文書"
    end

    def document_number
      order.order_number
    end

    def document_timestamp
      order.updated_at || order.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{order.order_number}")
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("注文番号", order.order_number, "状態", order_status_label(order.status), "注文日", jp_date(order.order_date))
      rows << label_value_row("得意先", order.customer.name, "希望納期", jp_date(order.requested_delivery_date), "先方担当者", order.ordered_by_name.presence || "-") if row_visible?("customer_delivery")
      rows << label_value_row("得意先担当者", order.customer.primary_contact.presence || "-", "メール", order.customer.contact_person_email.presence || order.customer.email.presence || "-", "電話", order.customer.contact_person_tel.presence || order.customer.tel.presence || "-") if row_visible?("contact_info")
      rows << full_width_value_row("納品先住所", order.delivery_address.presence || "-", columns: column_widths.size) if row_visible?("delivery_address")
      rows << full_width_value_row("備考", order.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << full_width_value_row("元見積", order.quotation&.quotation_number || "-", columns: column_widths.size) if row_visible?("source_quotation")
      rows << blank_row
      rows << section_row("注文明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("product_code", "商品コード")),
        header_cell(item_col_label("product_name", "商品名")),
        header_cell(item_col_label("quantity", "数量")),
        header_cell(item_col_label("unit_price", "単価")),
        header_cell(item_col_label("amount", "金額")),
        header_cell(item_col_label("allocated", "引当")),
        header_cell(item_col_label("delivered", "納品")),
        header_cell(item_col_label("status", "状態"))
      ]

      order.order_items.order(:line_no).each do |item|
        rows << [
          body_cell(item.product_code_snapshot),
          body_cell(item.product_name_snapshot),
          number_cell(item.quantity),
          number_cell(item.unit_price.to_i),
          number_cell(item.amount.to_i),
          number_cell(item.allocated_quantity),
          number_cell(item.delivered_quantity),
          body_cell(order_item_status_label(item.status))
        ]
      end

      rows << total_row("合計", order.total_amount.to_i, leading_blank_columns: 5, trailing_blank_columns: 1)
      rows
    end
  end
end
