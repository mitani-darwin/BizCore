module Admin
  # マネーフォワード クラウド会計向けの仕訳 CSV エクスポートを提供するコントローラ。
  class AccountingExportsController < BaseController
    def index
      @from_date = parse_date(params[:from_date]) || Date.current.beginning_of_month
      @to_date   = parse_date(params[:to_date])   || Date.current.end_of_month
    end

    def export_csv
      from_date = parse_date(params[:from_date]) || Date.current.beginning_of_month
      to_date   = parse_date(params[:to_date])   || Date.current.end_of_month

      csv = Accounting::MfJournalExporter.call(
        tenant:    current_tenant,
        from_date: from_date,
        to_date:   to_date
      )

      filename = "mf_journal_#{from_date.strftime('%Y%m%d')}_#{to_date.strftime('%Y%m%d')}.csv"
      send_data csv,
                filename: filename,
                type: "text/csv; charset=UTF-8",
                disposition: :attachment
    end

    private

    def parse_date(value)
      Date.parse(value) if value.present?
    rescue ArgumentError
      nil
    end
  end
end
