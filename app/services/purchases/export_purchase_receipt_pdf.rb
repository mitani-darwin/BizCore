# 入荷票 PDF 出力サービス。
# Purchases::ExportPurchaseReceiptXlsx と同じデータを PDF 形式で出力する。
module Purchases
  class ExportPurchaseReceiptPdf < Reports::BasePdf
    DEFAULT_COLUMN_WIDTHS = [ 14, 24, 10, 10, 10, 12, 14 ].freeze

    def initialize(purchase_receipt:, template: nil)
      @purchase_receipt = purchase_receipt
      @template = template
    end

    private

    attr_reader :purchase_receipt

    def document_title
      "入荷票"
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
          [ "入荷番号", purchase_receipt.purchase_receipt_number ],
          [ "状態", purchase_receipt_status_label(purchase_receipt.status) ],
          [ "入荷日", jp_date(purchase_receipt.received_on) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("supplier_order")
        info_rows << [
          [ "仕入先", purchase_receipt.supplier.name ],
          [ "発注番号", purchase_receipt.purchase_order.purchase_order_number ],
          [ "倉庫", purchase_receipt.warehouse.name ]
        ]
      end
      if row_visible?("staff_info")
        info_rows << [
          [ "入荷担当者", purchase_receipt.received_by_name.presence || "-" ],
          [ "登録日時", purchase_receipt.issued_at.present? ? purchase_receipt.issued_at.strftime("%Y/%m/%d %H:%M") : "-" ],
          [ "仕入先担当者", purchase_receipt.supplier.primary_contact.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "備考", purchase_receipt.remarks.presence || "-") if row_visible?("remarks")

      render_section_title(pdf, "入荷明細")

      col_count = column_widths.size
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)

      headers = [
        item_col_label("product_code", "商品コード"),
        item_col_label("product_name", "商品名"),
        item_col_label("quantity", "入荷数量"),
        item_col_label("returned", "返品済"),
        item_col_label("returnable", "返品可能"),
        item_col_label("unit_cost", "単価"),
        item_col_label("amount", "金額")
      ]
      item_rows = purchase_receipt.purchase_receipt_items.map do |item|
        [
          item.product_code_snapshot,
          item.product_name_snapshot,
          item.received_quantity,
          item.returned_quantity,
          item.returnable_quantity,
          item.unit_cost.to_i,
          item.amount.to_i
        ]
      end
      render_item_table(pdf, headers, item_rows, col_ws)

      render_total_row(pdf, "入荷合計", purchase_receipt.total_amount.to_i, col_count: col_count)
      render_total_row(pdf, "返品合計", purchase_receipt.total_return_amount.to_i, col_count: col_count)
      render_total_row(pdf, "値引合計", purchase_receipt.total_discount_amount.to_i, col_count: col_count)
      render_total_row(pdf, "調整後金額", purchase_receipt.net_amount.to_i, col_count: col_count)

      return if purchase_receipt.purchase_adjustments.empty?

      # 返品/値引き履歴セクション
      render_section_title(pdf, "返品/値引き履歴")

      adj_headers = [ "区分", "日付", "商品", "数量", "金額", "担当者", "理由" ]
      adj_rows = purchase_receipt.purchase_adjustments.order(:adjustment_date, :id).map do |adjustment|
        [
          purchase_adjustment_type_label(adjustment.adjustment_type),
          jp_date(adjustment.adjustment_date),
          adjustment.product_name_snapshot.presence || "-",
          adjustment.display_quantity.presence || "-",
          adjustment.amount.to_i,
          adjustment.processed_by_name.presence || "-",
          adjustment.reason.presence || "-"
        ]
      end
      render_item_table(pdf, adj_headers, adj_rows, col_ws)
    end
  end
end
