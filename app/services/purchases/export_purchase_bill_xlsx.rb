module Purchases
  class ExportPurchaseBillXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 24, 10, 12, 12, 12, 14 ].freeze

    def initialize(purchase_bill:, template: nil)
      @purchase_bill = purchase_bill
      @template = template
    end

    private

    attr_reader :purchase_bill

    def document_title
      "仕入請求書"
    end

    def document_number
      purchase_bill.bill_number
    end

    def document_timestamp
      purchase_bill.updated_at || purchase_bill.created_at
    end

    def worksheet_name
      sanitize_sheet_name("#{document_title}_#{purchase_bill.bill_number}")
    end

    def column_widths
      template ? template.resolved_column_widths : COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows.concat(company_header_rows)
      rows << title_row
      rows << blank_row
      rows << label_value_row("請求番号", purchase_bill.bill_number, "状態", purchase_bill_status_label(purchase_bill.status), "請求日", jp_date(purchase_bill.bill_date))
      rows << label_value_row("仕入先", purchase_bill.supplier.name, "支払期日", jp_date(purchase_bill.due_date), "仕入締め", purchase_bill.purchase_bill_batch&.batch_number || "-") if row_visible?("supplier_payment")
      rows << label_value_row("支払方法", payment_method_label(purchase_bill.payment_method_snapshot), "支払条件", payment_due_rule_label(purchase_bill.payment_due_rule_snapshot), "締日", "#{jp_date(purchase_bill.closing_date)} (#{purchase_bill.closing_day_snapshot || "-"}日締め)") if row_visible?("payment_terms")
      rows << label_value_row("仕入先担当者", purchase_bill.supplier.primary_contact.presence || "-", "メール", purchase_bill.supplier.contact_person_email.presence || purchase_bill.supplier.email.presence || "-", "電話", purchase_bill.supplier.contact_person_tel.presence || purchase_bill.supplier.tel.presence || "-") if row_visible?("contact_info")
      rows << full_width_value_row("請求期間", "#{jp_date(purchase_bill.billing_period_from)} 〜 #{jp_date(purchase_bill.billing_period_to)}", columns: column_widths.size) if row_visible?("billing_period")
      rows << full_width_value_row("仕入先住所", purchase_bill.supplier.full_address.presence || "-", columns: column_widths.size) if row_visible?("address")
      rows << full_width_value_row("備考", purchase_bill.remarks.presence || "-", columns: column_widths.size) if row_visible?("remarks")
      rows << full_width_value_row("再発行元", purchase_bill.reissued_from&.bill_number || "-", columns: column_widths.size) if purchase_bill.reissued_from.present?
      rows << blank_row
      rows << section_row("仕入請求明細", columns: column_widths.size)
      rows << [
        header_cell(item_col_label("description", "内容")),
        header_cell(item_col_label("quantity", "数量")),
        header_cell(item_col_label("unit_price", "単価")),
        header_cell(item_col_label("tax_category", "税区分")),
        header_cell(item_col_label("tax_amount", "税額")),
        header_cell(item_col_label("amount", "金額"))
      ]

      purchase_bill.purchase_bill_items.each do |item|
        rows << [
          body_cell(item.description),
          number_cell(item.quantity),
          number_cell(item.unit_price.to_i),
          body_cell(tax_category_label(item.tax_category)),
          number_cell(item.tax_amount.to_i),
          number_cell(item.amount.to_i)
        ]
      end

      rows << total_row("小計", purchase_bill.subtotal_amount.to_i, leading_blank_columns: 4)
      rows << total_row("税額", purchase_bill.tax_amount.to_i, leading_blank_columns: 4)
      rows << total_row("合計", purchase_bill.total_amount.to_i, leading_blank_columns: 4)
      rows << total_row("支払済", purchase_bill.paid_amount.to_i, leading_blank_columns: 4)
      rows << total_row("残高", purchase_bill.balance_amount.to_i, leading_blank_columns: 4)
      rows
    end
  end
end
