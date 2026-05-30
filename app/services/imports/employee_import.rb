module Imports
  # 従業員マスタの CSV 一括インポート。
  # 従業員番号が既存の場合は更新、なければ新規作成する。
  class EmployeeImport < BaseImport
    HEADERS = {
      employee_code:         "従業員番号",
      name:                  "氏名",
      employment_type:       "雇用形態(hourly/salaried)",
      status:                "在籍状況(active/inactive)",
      joined_on:             "入社日(YYYY/MM/DD)",
      base_hourly_wage:      "時給",
      base_monthly_salary:   "月給",
      email:                 "メール",
      tel:                   "電話番号"
    }.freeze

    SAMPLE_ROWS = [
      [ "EMP001", "山田太郎", "hourly", "active", "2024/04/01", "1200", "", "yamada@example.com", "090-0000-0001" ],
      [ "EMP002", "鈴木花子", "salaried", "active", "2024/04/01", "", "280000", "suzuki@example.com", "" ]
    ].freeze

    private

    def import_row(row, _line_number)
      code = row["従業員番号"].to_s.strip
      return { ok: false, errors: [ "従業員番号は必須です" ] } if code.blank?

      employee = tenant.employees.find_or_initialize_by(employee_code: code)
      employee.assign_attributes(build_attrs(row))

      if employee.save
        { ok: true }
      else
        { ok: false, errors: model_errors_to_array(employee) }
      end
    end

    def build_attrs(row)
      {
        name:                row["氏名"].to_s.strip.presence,
        employment_type:     normalize_employment_type(row["雇用形態(hourly/salaried)"]),
        status:              normalize_status(row["在籍状況(active/inactive)"]),
        joined_on:           parse_date(row["入社日(YYYY/MM/DD)"]),
        base_hourly_wage:    parse_decimal(row["時給"]),
        base_monthly_salary: parse_decimal(row["月給"]),
        email:               row["メール"].to_s.strip.presence,
        tel:                 row["電話番号"].to_s.strip.presence
      }.compact
    end

    def normalize_employment_type(value)
      v = value.to_s.strip.downcase
      Employee::EMPLOYMENT_TYPES.value?(v) ? v : nil
    end

    def normalize_status(value)
      v = value.to_s.strip.downcase
      Employee::STATUSES.value?(v) ? v : "active"
    end

    def parse_date(value)
      return nil if value.blank?

      Date.strptime(value.to_s.strip, "%Y/%m/%d")
    rescue ArgumentError, TypeError
      nil
    end

    def parse_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s.gsub(/[,，]/, "").strip)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
