module Deliveries
  class ExportXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [14, 26, 10, 12, 12, 14].freeze

    def initialize(delivery:)
      @delivery = delivery
    end

    private

    attr_reader :delivery

    def document_title
      "納品書"
    end

    def document_number
      delivery.delivery_number
    end

    def document_timestamp
      delivery.updated_at || delivery.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{delivery.delivery_number}")
    end

    def column_widths
      COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows << title_row
      rows << blank_row
      rows << label_value_row("納品番号", delivery.delivery_number, "状態", delivery_status_label(delivery.status), "納品日", jp_date(delivery.delivery_date))
      rows << label_value_row("得意先", delivery.customer.name, "注文番号", delivery.order.order_number, "発行日時", delivery.issued_at.present? ? delivery.issued_at.strftime("%Y/%m/%d %H:%M") : "-")
      rows << label_value_row("得意先担当者", delivery.customer.primary_contact.presence || "-", "メール", delivery.customer.contact_person_email.presence || delivery.customer.email.presence || "-", "電話", delivery.customer.contact_person_tel.presence || delivery.customer.tel.presence || "-")
      rows << full_width_value_row("納品先住所", delivery.delivery_address.presence || "-", columns: column_widths.size)
      rows << full_width_value_row("備考", delivery.remarks.presence || "-", columns: column_widths.size)
      rows << blank_row
      rows << section_row("納品明細", columns: column_widths.size)
      rows << [
        header_cell("商品コード"),
        header_cell("商品名"),
        header_cell("数量"),
        header_cell("単価"),
        header_cell("税区分"),
        header_cell("金額")
      ]

      delivery.delivery_items.each do |item|
        rows << [
          body_cell(item.product_code_snapshot),
          body_cell(item.product_name_snapshot),
          number_cell(item.delivered_quantity),
          number_cell(item.unit_price.to_i),
          body_cell(tax_category_label(item.tax_category)),
          number_cell(item.amount.to_i)
        ]
      end

      rows << total_row("合計", delivery.total_amount.to_i, leading_blank_columns: 4)
      rows
    end
  end
end
