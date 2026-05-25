module Payrolls
  class ExportPayrollXlsx < Reports::BaseXlsx
    COLUMN_WIDTHS = [ 14, 18, 12, 12, 10, 14, 14, 14, 16 ].freeze

    def initialize(payroll_run:)
      @payroll_run = payroll_run
      @template = nil
    end

    private

    attr_reader :payroll_run

    def document_title
      "給与計算明細"
    end

    def document_number
      payroll_run.run_number
    end

    def document_timestamp
      payroll_run.updated_at
    end

    def worksheet_name
      sanitize_sheet_name("#{payroll_run.payroll_month.strftime('%Y%m')}_給与明細")
    end

    def column_widths
      COLUMN_WIDTHS
    end

    def build_rows
      rows = []
      rows << title_row
      rows << blank_row
      rows << label_value_row(
        "給与計算番号", payroll_run.run_number,
        "対象月",       payroll_run.payroll_month.strftime("%Y年%m月"),
        "状態",         payroll_run_status_label
      )
      rows << label_value_row(
        "生成日時", fmt_datetime(payroll_run.generated_at),
        "確定日時", fmt_datetime(payroll_run.confirmed_at),
        "メモ",     payroll_run.note.presence || "-"
      )
      rows << blank_row
      rows << section_row("給与明細一覧", columns: COLUMN_WIDTHS.size)
      rows << [
        header_cell("従業員コード"),
        header_cell("氏名"),
        header_cell("実働時間"),
        header_cell("残業時間"),
        header_cell("有給（日）"),
        header_cell("基本給"),
        header_cell("残業代"),
        header_cell("有給分"),
        header_cell("支給額")
      ]

      entries.each do |entry|
        rows << [
          body_cell(entry.employee.employee_code),
          body_cell(entry.employee.name),
          body_cell(fmt_minutes(entry.worked_minutes)),
          body_cell(fmt_minutes(entry.overtime_minutes)),
          body_cell(entry.paid_leave_days.to_d.to_s),
          number_cell(entry.base_pay.to_i),
          number_cell(entry.overtime_pay.to_i),
          number_cell(entry.paid_leave_pay.to_i),
          number_cell(entry.gross_pay.to_i)
        ]
      end

      rows << total_row("支給総額", payroll_run.total_gross_pay.to_i, leading_blank_columns: 7, trailing_blank_columns: 0)
      rows
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
