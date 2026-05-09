module Purchases
  class ExportPurchaseOrderXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 14, 24, 10, 10, 10, 12, 14, 14 ].freeze

    def initialize(purchase_order:, template: nil)
      @purchase_order = purchase_order
      @template = template
    end

    private

    attr_reader :purchase_order

    def document_title
      "発注書"
    end

    def document_number
      purchase_order.purchase_order_number
    end

    def document_timestamp
      purchase_order.updated_at || purchase_order.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{purchase_order.purchase_order_number}")
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("発注番号", purchase_order.purchase_order_number, "状態", purchase_order_status_label(purchase_order.status), "発注日", jp_date(purchase_order.order_date))
      rows << label_value_row("仕入先", purchase_order.supplier.name, "希望納期", jp_date(purchase_order.requested_delivery_date), "発注担当者", purchase_order.ordered_by_name.presence || "-") if row_visible?("supplier_delivery")
      rows << label_value_row("仕入先担当者", purchase_order.supplier.primary_contact.presence || "-", "メール", purchase_order.supplier.contact_person_email.presence || purchase_order.supplier.email.presence || "-", "電話", purchase_order.supplier.contact_person_tel.presence || purchase_order.supplier.tel.presence || "-") if row_visible?("contact_info")
      rows << full_width_value_row("入荷倉庫", purchase_order.warehouse.name, columns: column_widths.size) if row_visible?("warehouse")
      rows << full_width_value_row("備考", purchase_order.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << blank_row
      rows << section_row("発注明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("product_code", "商品コード")),
        header_cell(item_col_label("product_name", "商品名")),
        header_cell(item_col_label("quantity", "発注数量")),
        header_cell(item_col_label("received", "入荷済")),
        header_cell(item_col_label("remaining", "残数量")),
        header_cell(item_col_label("unit_cost", "単価")),
        header_cell(item_col_label("amount", "金額")),
        header_cell(item_col_label("status", "状態"))
      ]

      purchase_order.purchase_order_items.order(:line_no).each do |item|
        rows << [
          body_cell(item.product_code_snapshot),
          body_cell(item.product_name_snapshot),
          number_cell(item.quantity),
          number_cell(item.received_quantity),
          number_cell(item.remaining_quantity),
          number_cell(item.unit_cost.to_i),
          number_cell(item.amount.to_i),
          body_cell(purchase_order_item_status_label(item.status))
        ]
      end

      rows << total_row("合計", purchase_order.total_amount.to_i, leading_blank_columns: 5, trailing_blank_columns: 1)
      rows << total_row("返品合計", purchase_order.total_return_amount.to_i, leading_blank_columns: 5, trailing_blank_columns: 1)
      rows << total_row("値引合計", purchase_order.total_discount_amount.to_i, leading_blank_columns: 5, trailing_blank_columns: 1)
      rows
    end
  end
end
