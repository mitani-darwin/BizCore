module Purchases
  class ExportPurchaseReceiptXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 14, 24, 10, 10, 10, 12, 14 ].freeze

    def initialize(purchase_receipt:, template: nil)
      @purchase_receipt = purchase_receipt
      @template = template
    end

    private

    attr_reader :purchase_receipt

    def document_title
      "入荷票"
    end

    def document_number
      purchase_receipt.purchase_receipt_number
    end

    def document_timestamp
      purchase_receipt.updated_at || purchase_receipt.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{purchase_receipt.purchase_receipt_number}")
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("入荷番号", purchase_receipt.purchase_receipt_number, "状態", purchase_receipt_status_label(purchase_receipt.status), "入荷日", jp_date(purchase_receipt.received_on))
      rows << label_value_row("仕入先", purchase_receipt.supplier.name, "発注番号", purchase_receipt.purchase_order.purchase_order_number, "倉庫", purchase_receipt.warehouse.name) if row_visible?("supplier_order")
      rows << label_value_row("入荷担当者", purchase_receipt.received_by_name.presence || "-", "登録日時", purchase_receipt.issued_at.present? ? purchase_receipt.issued_at.strftime("%Y/%m/%d %H:%M") : "-", "仕入先担当者", purchase_receipt.supplier.primary_contact.presence || "-") if row_visible?("staff_info")
      rows << full_width_value_row("備考", purchase_receipt.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << blank_row
      rows << section_row("入荷明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("product_code", "商品コード")),
        header_cell(item_col_label("product_name", "商品名")),
        header_cell(item_col_label("quantity", "入荷数量")),
        header_cell(item_col_label("returned", "返品済")),
        header_cell(item_col_label("returnable", "返品可能")),
        header_cell(item_col_label("unit_cost", "単価")),
        header_cell(item_col_label("amount", "金額"))
      ]

      purchase_receipt.purchase_receipt_items.each do |item|
        rows << [
          body_cell(item.product_code_snapshot),
          body_cell(item.product_name_snapshot),
          number_cell(item.received_quantity),
          number_cell(item.returned_quantity),
          number_cell(item.returnable_quantity),
          number_cell(item.unit_cost.to_i),
          number_cell(item.amount.to_i)
        ]
      end

      rows << total_row("入荷合計", purchase_receipt.total_amount.to_i, leading_blank_columns: 4, trailing_blank_columns: 1)
      rows << total_row("返品合計", purchase_receipt.total_return_amount.to_i, leading_blank_columns: 4, trailing_blank_columns: 1)
      rows << total_row("値引合計", purchase_receipt.total_discount_amount.to_i, leading_blank_columns: 4, trailing_blank_columns: 1)
      rows << total_row("調整後金額", purchase_receipt.net_amount.to_i, leading_blank_columns: 4, trailing_blank_columns: 1)

      return rows if purchase_receipt.purchase_adjustments.empty?

      rows << blank_row
      rows << section_row("返品/値引き履歴", columns: column_widths.size)
      rows << [
        header_cell("区分"),
        header_cell("日付"),
        header_cell("商品"),
        header_cell("数量"),
        header_cell("金額"),
        header_cell("担当者"),
        header_cell("理由")
      ]

      purchase_receipt.purchase_adjustments.order(:adjustment_date, :id).each do |adjustment|
        rows << [
          body_cell(purchase_adjustment_type_label(adjustment.adjustment_type)),
          body_cell(jp_date(adjustment.adjustment_date)),
          body_cell(adjustment.product_name_snapshot.presence || "-"),
          body_cell(adjustment.display_quantity.presence || "-"),
          number_cell(adjustment.amount.to_i),
          body_cell(adjustment.processed_by_name.presence || "-"),
          body_cell(adjustment.reason.presence || "-")
        ]
      end

      rows
    end
  end
end
