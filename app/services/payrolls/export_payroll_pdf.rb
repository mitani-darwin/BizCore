module Payrolls
  class ExportPayrollPdf < Reports::BasePdf
    # 相対比率（横A4で pdf_column_widths がスケールする）
    DEFAULT_COLUMN_WIDTHS = [ 10, 18, 8, 8, 6, 10, 10, 10, 12 ].freeze

    def initialize(payroll_run:)
      @payroll_run = payroll_run
      @template = nil
    end

    # A4 横レイアウトで出力
    def call
      pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: PAGE_MARGINS)
      setup_fonts(pdf)
      build_pdf(pdf)
      pdf.render
    end

    private

    attr_reader :payroll_run

    def document_title
      "給与計算明細"
    end

    def default_column_widths
      DEFAULT_COLUMN_WIDTHS
    end

    def build_pdf(pdf)
      render_title(pdf)

      render_info_table(pdf, [
        [
          [ "給与計算番号", payroll_run.run_number ],
          [ "対象月",       payroll_run.payroll_month.strftime("%Y年%m月") ],
          [ "状態",         payroll_run_status_label ]
        ],
        [
          [ "生成日時", fmt_datetime(payroll_run.generated_at) ],
          [ "確定日時", fmt_datetime(payroll_run.confirmed_at) ],
          [ "メモ",     payroll_run.note.presence || "-" ]
        ]
      ])

      render_section_title(pdf, "給与明細一覧")

      usable_width = pdf.bounds.width
      col_ws = pdf_column_widths(usable_width)
      col_count = DEFAULT_COLUMN_WIDTHS.size

      headers = %w[従業員コード 氏名 実働時間 残業時間 有給（日） 基本給 残業代 有給分 支給額]
      entry_rows = entries.map do |entry|
        [
          entry.employee.employee_code,
          entry.employee.name,
          fmt_minutes(entry.worked_minutes),
          fmt_minutes(entry.overtime_minutes),
          entry.paid_leave_days.to_d.to_s,
          number_with_delimiter(entry.base_pay.to_i),
          number_with_delimiter(entry.overtime_pay.to_i),
          number_with_delimiter(entry.paid_leave_pay.to_i),
          number_with_delimiter(entry.gross_pay.to_i)
        ]
      end
      render_item_table(pdf, headers, entry_rows, col_ws)

      render_total_row(pdf, "支給総額", payroll_run.total_gross_pay.to_i, col_count: col_count)
    end

    def entries
      @entries ||= payroll_run.payroll_entries
                              .joins(:employee)
                              .includes(:employee)
                              .order("employees.employee_code ASC")
    end

    def payroll_run_status_label
      payroll_run.confirmed? ? "確定" : "計算済み"
    end

    def fmt_minutes(minutes)
      h = minutes.to_i / 60
      m = minutes.to_i % 60
      format("%d:%02d", h, m)
    end

    def fmt_datetime(value)
      value&.strftime("%Y/%m/%d %H:%M") || "-"
    end
  end
end
