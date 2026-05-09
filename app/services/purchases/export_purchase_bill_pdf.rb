# 仕入請求書 PDF 出力サービス。
# Purchases::ExportPurchaseBillXlsx と同じデータを PDF 形式で出力する。
module Purchases
  class ExportPurchaseBillPdf < Reports::BasePdf
    DEFAULT_COLUMN_WIDTHS = [ 24, 10, 12, 12, 12, 14 ].freeze

    def initialize(purchase_bill:, template: nil)
      @purchase_bill = purchase_bill
      @template = template
    end

    private

    attr_reader :purchase_bill

    def document_title
      "仕入請求書"
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
          [ "請求番号", purchase_bill.bill_number ],
          [ "状態", purchase_bill_status_label(purchase_bill.status) ],
          [ "請求日", jp_date(purchase_bill.bill_date) ]
        ]
      ])

      # テンプレートで制御される行
      info_rows = []
      if row_visible?("supplier_payment")
        info_rows << [
          [ "仕入先", purchase_bill.supplier.name ],
          [ "支払期日", jp_date(purchase_bill.due_date) ],
          [ "仕入締め", purchase_bill.purchase_bill_batch&.batch_number || "-" ]
        ]
      end
      if row_visible?("payment_terms")
        info_rows << [
          [ "支払方法", payment_method_label(purchase_bill.payment_method_snapshot) ],
          [ "支払条件", payment_due_rule_label(purchase_bill.payment_due_rule_snapshot) ],
          [ "締日", "#{jp_date(purchase_bill.closing_date)} (#{purchase_bill.closing_day_snapshot || "-"}日締め)" ]
        ]
      end
      if row_visible?("contact_info")
        info_rows << [
          [ "仕入先担当者", purchase_bill.supplier.primary_contact.presence || "-" ],
          [ "メール", purchase_bill.supplier.contact_person_email.presence || purchase_bill.supplier.email.presence || "-" ],
          [ "電話", purchase_bill.supplier.contact_person_tel.presence || purchase_bill.supplier.tel.presence || "-" ]
        ]
      end
      render_info_table(pdf, info_rows) if info_rows.any?

      render_full_width_row(pdf, "請求期間", "#{jp_date(purchase_bill.billing_period_from)} 〜 #{jp_date(purchase_bill.billing_period_to)}") if row_visible?("billing_period")
      render_full_width_row(pdf, "仕入先住所", purchase_bill.supplier.full_address.presence || "-") if row_visible?("address")
      render_full_width_row(pdf, "備考", purchase_bill.remarks.presence || "-") if row_visible?("remarks")
      render_full_width_row(pdf, "再発行元", purchase_bill.reissued_from.bill_number) if purchase_bill.reissued_from.present?

      render_section_title(pdf, "仕入請求明細")

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
      item_rows = purchase_bill.purchase_bill_items.map do |item|
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

      render_total_row(pdf, "小計", purchase_bill.subtotal_amount.to_i, col_count: col_count)
      render_total_row(pdf, "税額", purchase_bill.tax_amount.to_i, col_count: col_count)
      render_total_row(pdf, "合計", purchase_bill.total_amount.to_i, col_count: col_count)
      render_total_row(pdf, "支払済", purchase_bill.paid_amount.to_i, col_count: col_count)
      render_total_row(pdf, "残高", purchase_bill.balance_amount.to_i, col_count: col_count)
    end
  end
end
