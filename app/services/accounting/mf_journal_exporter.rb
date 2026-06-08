module Accounting
  # マネーフォワード クラウド会計の仕訳インポート CSV を生成するサービス。
  # 売上側（請求書・入金）と仕入側（仕入請求書・支払）の仕訳を出力する。
  #
  # 勘定科目はデフォルト値を使用する。将来的にテナント単位での設定変更に対応できるよう
  # ACCOUNTS ハッシュを切り出している。
  class MfJournalExporter
    HEADER = %w[
      取引No 取引日
      借方勘定科目 借方補助科目 借方部門 借方金額 借方消費税額 借方消費税区分
      貸方勘定科目 貸方補助科目 貸方部門 貸方金額 貸方消費税額 貸方消費税区分
      摘要
    ].freeze

    ACCOUNTS = {
      accounts_receivable: "売掛金",
      sales:               "売上高",
      bank:                "普通預金",
      accounts_payable:    "買掛金",
      purchases:           "仕入高"
    }.freeze

    SALES_TAX_LABEL = {
      "taxable_10"  => "課税売上10%",
      "taxable_8"   => "課税売上8%(軽)",
      "non_taxable" => "対象外"
    }.freeze

    PURCHASE_TAX_LABEL = {
      "taxable_10"  => "課税仕入10%",
      "taxable_8"   => "課税仕入8%(軽)",
      "non_taxable" => "対象外"
    }.freeze

    NON_TAXABLE = "対象外"

    def self.call(tenant:, from_date:, to_date:)
      new(tenant: tenant, from_date: from_date, to_date: to_date).call
    end

    def initialize(tenant:, from_date:, to_date:)
      @tenant    = tenant
      @from_date = from_date
      @to_date   = to_date
      @seq       = 0
    end

    def call
      "﻿" + CSV.generate(encoding: "UTF-8", force_quotes: true) do |csv|
        csv << HEADER
        append_invoice_rows(csv)
        append_payment_rows(csv)
        append_purchase_bill_rows(csv)
        append_supplier_payment_rows(csv)
      end
    end

    private

    attr_reader :tenant, :from_date, :to_date

    def next_seq
      @seq += 1
    end

    def fmt_date(date)
      date&.strftime("%Y/%m/%d") || ""
    end

    def blank_debit
      [ "", "", "", 0, 0, NON_TAXABLE ]
    end

    def blank_credit
      [ "", "", "", 0, 0, NON_TAXABLE ]
    end

    # ── 売上側 ──────────────────────────────────────────────────────────

    def append_invoice_rows(csv)
      invoices = tenant.invoices
                       .where(invoice_date: from_date..to_date)
                       .where.not(status: "cancelled")
                       .includes(:customer, :invoice_items)

      invoices.each do |invoice|
        no      = next_seq
        date    = fmt_date(invoice.invoice_date)
        summary = "#{invoice.invoice_number} #{invoice.customer.name}"

        breakdown = invoice.tax_breakdown
        non_tax_subtotal = invoice.invoice_items
                                  .select { |i| i.tax_category == "non_taxable" }
                                  .sum { |i| i.amount.to_d }

        all_categories = breakdown.keys
        all_categories << "non_taxable" if non_tax_subtotal.positive?

        all_categories.each_with_index do |category, idx|
          if category == "non_taxable"
            subtotal = non_tax_subtotal
            tax      = 0
          else
            subtotal = breakdown[category][:subtotal]
            tax      = breakdown[category][:tax]
          end

          if idx == 0
            debit = [ ACCOUNTS[:accounts_receivable], "", "", invoice.total_amount.to_i, 0, NON_TAXABLE ]
          else
            debit = blank_debit
          end
          credit = [ ACCOUNTS[:sales], "", "", subtotal.to_i, tax.to_i, SALES_TAX_LABEL[category] ]
          csv << [ no, date, *debit, *credit, summary ]
        end

        # 仕訳行がない場合（明細ゼロ）は合計行だけ出す
        if all_categories.empty?
          debit  = [ ACCOUNTS[:accounts_receivable], "", "", invoice.total_amount.to_i, 0, NON_TAXABLE ]
          credit = [ ACCOUNTS[:sales], "", "", invoice.subtotal_amount.to_i, invoice.tax_amount.to_i, SALES_TAX_LABEL["taxable_10"] ]
          csv << [ no, date, *debit, *credit, summary ]
        end
      end
    end

    def append_payment_rows(csv)
      payments = tenant.payments
                       .where(payment_date: from_date..to_date)
                       .includes(:customer)

      payments.each do |payment|
        no      = next_seq
        date    = fmt_date(payment.payment_date)
        summary = "#{payment.payment_number} #{payment.customer.name}"
        amount  = payment.amount.to_i

        debit  = [ ACCOUNTS[:bank], "", "", amount, 0, NON_TAXABLE ]
        credit = [ ACCOUNTS[:accounts_receivable], "", "", amount, 0, NON_TAXABLE ]
        csv << [ no, date, *debit, *credit, summary ]
      end
    end

    # ── 仕入側 ──────────────────────────────────────────────────────────

    def append_purchase_bill_rows(csv)
      bills = tenant.purchase_bills
                    .where(bill_date: from_date..to_date)
                    .where.not(status: "cancelled")
                    .includes(:supplier, :purchase_bill_items)

      bills.each do |bill|
        no      = next_seq
        date    = fmt_date(bill.bill_date)
        summary = "#{bill.bill_number} #{bill.supplier.name}"

        breakdown = bill.tax_breakdown
        non_tax_subtotal = bill.purchase_bill_items
                               .select { |i| i.tax_category == "non_taxable" }
                               .sum { |i| i.amount.to_d }

        all_categories = breakdown.keys
        all_categories << "non_taxable" if non_tax_subtotal.positive?

        all_categories.each_with_index do |category, idx|
          if category == "non_taxable"
            subtotal = non_tax_subtotal
            tax      = 0
          else
            subtotal = breakdown[category][:subtotal]
            tax      = breakdown[category][:tax]
          end

          debit = [ ACCOUNTS[:purchases], "", "", subtotal.to_i, tax.to_i, PURCHASE_TAX_LABEL[category] ]
          if idx == 0
            credit = [ ACCOUNTS[:accounts_payable], "", "", bill.total_amount.to_i, 0, NON_TAXABLE ]
          else
            credit = blank_credit
          end
          csv << [ no, date, *debit, *credit, summary ]
        end

        if all_categories.empty?
          debit  = [ ACCOUNTS[:purchases], "", "", bill.subtotal_amount.to_i, bill.tax_amount.to_i, PURCHASE_TAX_LABEL["taxable_10"] ]
          credit = [ ACCOUNTS[:accounts_payable], "", "", bill.total_amount.to_i, 0, NON_TAXABLE ]
          csv << [ no, date, *debit, *credit, summary ]
        end
      end
    end

    def append_supplier_payment_rows(csv)
      payments = tenant.supplier_payments
                       .where(payment_date: from_date..to_date)
                       .includes(:supplier)

      payments.each do |payment|
        no      = next_seq
        date    = fmt_date(payment.payment_date)
        summary = "#{payment.payment_number} #{payment.supplier.name}"
        amount  = payment.amount.to_i

        debit  = [ ACCOUNTS[:accounts_payable], "", "", amount, 0, NON_TAXABLE ]
        credit = [ ACCOUNTS[:bank], "", "", amount, 0, NON_TAXABLE ]
        csv << [ no, date, *debit, *credit, summary ]
      end
    end
  end
end
