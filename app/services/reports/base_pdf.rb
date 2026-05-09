require "prawn"
require "prawn/table"

# PDF 帳票サービスの基底クラス。
# 各帳票サービスはこのクラスを継承し、#build_pdf と #document_title を実装する。
module Reports
  class BasePdf
    MIME_TYPE = "application/pdf".freeze
    # 上・右・下・左（単位: pt）
    PAGE_MARGINS = [ 40, 40, 50, 40 ].freeze

    # クラスメソッド経由で呼び出す: SomeService.call(...)
    def self.call(**kwargs)
      new(**kwargs).call
    end

    attr_reader :template

    # PDF バイナリ文字列を返す
    def call
      pdf = Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: PAGE_MARGINS)
      setup_fonts(pdf)
      build_pdf(pdf)
      pdf.render
    end

    private

    # サブクラスで実装: PDF 本文を組み立てる
    def build_pdf(pdf)
      raise NotImplementedError
    end

    # サブクラスで実装: 帳票タイトル文字列
    def document_title
      raise NotImplementedError
    end

    # サブクラスで実装: デフォルト列幅の配列（数値）
    def default_column_widths
      raise NotImplementedError
    end

    # ---------- フォント設定 ----------

    def setup_fonts(pdf)
      font_path = Reports::PdfFont.font_path
      pdf.font_families.update(
        "JP" => {
          normal: font_path,
          bold: font_path,
          italic: font_path,
          bold_italic: font_path
        }
      )
      pdf.font "JP"
      pdf.font_size 9
    end

    # ---------- 列幅ヘルパー ----------

    # テンプレート設定を加味した列幅（PDF ポイント単位）の配列を返す。
    # 浮動小数点誤差で合計が usable_width を超えないよう最後の列で端数を吸収する。
    def pdf_column_widths(usable_width)
      widths = column_widths
      total = widths.sum.to_f
      n = widths.size
      return Array.new(n) { (usable_width / n).floor(2) }.tap { |a| a[-1] = (usable_width - a[0..-2].sum).round(2) } if total.zero?

      result = widths.map { |w| (w / total * usable_width).floor(2) }
      result[-1] = (usable_width - result[0..-2].sum).round(2)
      result
    end

    def column_widths
      return default_column_widths unless template

      template.resolved_column_widths.presence || default_column_widths
    end

    # ---------- テンプレートヘルパー ----------

    def row_visible?(key)
      return true unless template

      template.row_visible?(key)
    end

    def item_col_label(key, default_label)
      return default_label unless template

      template.item_column_label(key, default_label)
    end

    # ---------- 共通描画ヘルパー ----------

    # 会社ヘッダーブロックを描画する（テンプレートで有効な場合のみ）
    def render_company_header(pdf)
      return unless template&.company_header_enabled?

      lines = []
      lines << template.company_name if template.company_name.present?
      addr_parts = [ template.company_postal_code, template.company_address ].select(&:present?)
      lines << "〒#{addr_parts.join(' ')}" if addr_parts.any?
      lines << "TEL: #{template.company_tel}" if template.company_tel.present?
      lines << "Email: #{template.company_email}" if template.company_email.present?
      return if lines.empty?

      usable_width = pdf.bounds.width
      pdf.bounding_box([ 0, pdf.cursor ], width: usable_width) do
        lines.each_with_index do |line, i|
          pdf.text line, size: (i.zero? ? 11 : 8), style: (i.zero? ? :bold : :normal)
        end
        pdf.stroke_horizontal_rule
      end
      pdf.move_down 10
    end

    # 帳票タイトルを中央揃えで描画する
    def render_title(pdf)
      pdf.text document_title, size: 16, style: :bold, align: :center
      pdf.move_down 8
    end

    # ラベル・値ペアのメタ情報テーブルを描画する
    # rows: [ [ [label, value], [label, value], ... ], ... ]
    def render_info_table(pdf, rows)
      return if rows.empty?

      usable_width = pdf.bounds.width
      base_w = (usable_width / 6.0).floor(2)
      col_ws = Array.new(5, base_w) + [ (usable_width - base_w * 5).round(2) ]

      table_data = rows.map do |pairs|
        row_cells = []
        3.times do |i|
          label, value = pairs[i] || [ "", "" ]
          row_cells << { content: label.to_s, background_color: "F1F5F9", font_style: :bold }
          row_cells << { content: value.to_s }
        end
        row_cells
      end

      pdf.table(table_data, cell_style: { padding: [ 3, 4 ] }) do |t|
        col_ws.each_with_index { |w, i| t.columns(i).width = w }
        t.cells.border_width = 0.5
        t.cells.border_color = "CBD5E1"
      end
      pdf.move_down 6
    end

    # 全幅のラベル・値行を描画する
    def render_full_width_row(pdf, label, value)
      usable_width = pdf.bounds.width
      label_w = usable_width * 0.2
      value_w = usable_width * 0.8
      pdf.table(
        [ [
          { content: label.to_s, background_color: "F1F5F9", font_style: :bold },
          { content: value.to_s }
        ] ],
        cell_style: { padding: [ 3, 4 ] }
      ) do |t|
        t.columns(0).width = label_w
        t.columns(1).width = value_w
        t.cells.border_width = 0.5
        t.cells.border_color = "CBD5E1"
      end
      pdf.move_down 2
    end

    # 明細セクションのタイトル行を描画する
    def render_section_title(pdf, title)
      pdf.move_down 6
      pdf.text title, size: 9, style: :bold
      pdf.move_down 2
    end

    # 明細アイテムのテーブルを描画する
    # col_widths: 列幅の配列（pt単位）
    def render_item_table(pdf, headers, rows, col_widths)
      usable_width = pdf.bounds.width
      header_row = headers.map { |h| { content: h.to_s, background_color: "F1F5F9", font_style: :bold } }
      data_rows = rows.map { |row| row.map { |cell| { content: cell.to_s } } }
      table_data = [ header_row ] + data_rows

      pdf.table(table_data, cell_style: { padding: [ 3, 4 ] }) do |t|
        col_widths.each_with_index { |w, i| t.columns(i).width = w }
        t.row(0).background_color = "F1F5F9"
        t.cells.border_width = 0.5
        t.cells.border_color = "CBD5E1"
      end
      pdf.move_down 4
    end

    # 合計行（右端2列に合計ラベルと値を表示）を描画する
    def render_total_row(pdf, label, amount, col_count:)
      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)
      leading_w = col_ws[0..(col_count - 3)].sum
      label_w = col_ws[col_count - 2]
      value_w = col_ws[col_count - 1]
      row = [
        { content: "", borders: [] },
        { content: label.to_s, background_color: "E0F2FE", font_style: :bold, align: :right },
        { content: number_with_delimiter(amount), background_color: "E0F2FE", font_style: :bold, align: :right }
      ]
      pdf.table([ row ], cell_style: { padding: [ 3, 4 ] }) do |t|
        t.columns(0).width = leading_w
        t.columns(1).width = label_w
        t.columns(2).width = value_w
        t.cells.border_width = 0.5
        t.cells.border_color = "CBD5E1"
      end
    end

    # ---------- 汎用フォーマットヘルパー ----------

    def number_with_delimiter(number)
      ActionController::Base.helpers.number_with_delimiter(number.to_i)
    end

    def jp_date(value)
      value.present? ? value.strftime("%Y/%m/%d") : "-"
    end

    # ---------- ラベル変換（BaseXlsx と同一） ----------

    def tax_category_label(value)
      { "taxable_10" => "課税 10%", "taxable_8" => "軽減税率 8%", "non_taxable" => "非課税" }
        .fetch(value.to_s, fallback_label(value))
    end

    def payment_method_label(value)
      { "bank_transfer" => "銀行振込", "direct_debit" => "口座振替", "cash" => "現金", "other" => "その他" }
        .fetch(value.to_s, fallback_label(value))
    end

    def invoice_delivery_method_label(value)
      { "email" => "メール", "postal" => "郵送", "hand" => "手渡し" }
        .fetch(value.to_s, fallback_label(value))
    end

    def payment_due_rule_label(value)
      { "end_of_month" => "当月末", "next_month_end" => "翌月末", "next_two_month_end" => "翌々月末", "custom" => "個別設定" }
        .fetch(value.to_s, fallback_label(value))
    end

    def order_status_label(value)
      { "draft" => "下書き", "sent" => "送信済", "accepted" => "受注済", "allocated" => "在庫確保済", "delivered" => "納品済", "billed" => "請求済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def order_item_status_label(value)
      { "pending" => "未処理", "allocated" => "在庫確保済", "delivered" => "納品済", "billed" => "請求済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def delivery_status_label(value)
      { "issued" => "発行済", "billed" => "請求済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def invoice_status_label(value)
      { "issued" => "未入金", "partially_paid" => "一部入金", "paid" => "入金済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def purchase_order_status_label(value)
      { "draft" => "下書き", "sent" => "発注済", "partially_received" => "一部入荷", "received" => "入荷完了", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def purchase_order_item_status_label(value)
      { "pending" => "未入荷", "partially_received" => "一部入荷", "received" => "入荷済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def purchase_receipt_status_label(value)
      { "issued" => "入荷済", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def purchase_adjustment_type_label(value)
      { "purchase_return" => "返品", "discount" => "値引き" }
        .fetch(value.to_s, fallback_label(value))
    end

    def purchase_bill_status_label(value)
      { "issued" => "未払", "partially_paid" => "一部支払", "paid" => "支払済", "credit" => "差引超過", "cancelled" => "取消" }
        .fetch(value.to_s, fallback_label(value))
    end

    def fallback_label(value)
      value.to_s.presence || "-"
    end
  end
end
