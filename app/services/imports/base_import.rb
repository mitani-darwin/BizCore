require "csv"

module Imports
  # CSV 一括インポートの基底クラス。
  # サブクラスは HEADERS・SAMPLE_ROWS・import_row を実装する。
  # コード（一意キー）が既存の場合は更新、なければ新規作成する upsert 方式を採用する。
  class BaseImport
    # インポート結果を保持する値オブジェクト。
    # failed_rows の各要素: { row: 行番号, data: Hash, errors: [String] }
    Result = Struct.new(:total, :succeeded, :failed_rows, keyword_init: true)

    def self.call(tenant:, csv_string:)
      new(tenant: tenant, csv_string: csv_string).call
    end

    def initialize(tenant:, csv_string:)
      @tenant     = tenant
      @csv_string = csv_string
    end

    def call
      rows = parse_csv
      failed_rows = []
      succeeded = 0

      rows.each_with_index do |row, index|
        line_number = index + 2 # ヘッダー行が1行目なので2行目から
        result = import_row(row, line_number)
        if result[:ok]
          succeeded += 1
        else
          failed_rows << { row: line_number, data: row.to_h, errors: result[:errors] }
        end
      end

      Result.new(total: rows.size, succeeded: succeeded, failed_rows: failed_rows)
    end

    # CSV テンプレートを生成して返す。
    def self.template_csv
      CSV.generate(encoding: "UTF-8") do |csv|
        csv << self::HEADERS.values
        self::SAMPLE_ROWS.each { |row| csv << row }
      end
    end

    private

    attr_reader :tenant, :csv_string

    # サブクラスで実装: row (CSV::Row) を受け取り { ok: true } または { ok: false, errors: [...] } を返す。
    def import_row(row, line_number)
      raise NotImplementedError
    end

    def parse_csv
      # BOM 除去・改行コード正規化
      normalized = csv_string.to_s
                             .delete_prefix("\xEF\xBB\xBF")
                             .encode("UTF-8", invalid: :replace, undef: :replace)
      rows = CSV.parse(normalized, headers: true, skip_blanks: true)
      rows.reject { |row| row.to_h.values.all?(&:blank?) }
    rescue CSV::MalformedCSVError => e
      raise ArgumentError, "CSV の形式が正しくありません: #{e.message}"
    end

    def model_errors_to_array(model)
      model.errors.full_messages
    end
  end
end
