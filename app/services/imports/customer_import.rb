module Imports
  # 得意先マスタの CSV 一括インポート。
  # 得意先コードが既存の場合は更新、なければ新規作成する。
  class CustomerImport < BaseImport
    HEADERS = {
      code:                        "得意先コード",
      name:                        "得意先名",
      status:                      "ステータス(active/inactive)",
      email:                       "メール",
      tel:                         "電話番号",
      postal_code:                 "郵便番号",
      address1:                    "住所1",
      address2:                    "住所2",
      contact_person_department:   "担当部署",
      contact_person_name:         "担当者名",
      contact_person_email:        "担当者メール"
    }.freeze

    SAMPLE_ROWS = [
      [ "C001", "東京商事株式会社", "active", "info@tokyo-shoji.example.com", "03-0000-1111",
        "100-0001", "東京都千代田区千代田1-1", "", "営業部", "田中一郎", "tanaka@tokyo-shoji.example.com" ],
      [ "C002", "大阪産業", "active", "", "06-0000-2222",
        "530-0001", "大阪府大阪市北区梅田1-1", "", "", "山田次郎", "" ]
    ].freeze

    private

    def import_row(row, _line_number)
      code = row["得意先コード"].to_s.strip
      return { ok: false, errors: [ "得意先コードは必須です" ] } if code.blank?

      customer = tenant.customers.find_or_initialize_by(code: code)
      customer.assign_attributes(build_attrs(row))

      if customer.save
        { ok: true }
      else
        { ok: false, errors: model_errors_to_array(customer) }
      end
    end

    def build_attrs(row)
      {
        name:                      row["得意先名"].to_s.strip.presence,
        status:                    normalize_status(row["ステータス(active/inactive)"]),
        email:                     row["メール"].to_s.strip.presence,
        tel:                       row["電話番号"].to_s.strip.presence,
        postal_code:               row["郵便番号"].to_s.strip.presence,
        address1:                  row["住所1"].to_s.strip.presence,
        address2:                  row["住所2"].to_s.strip.presence,
        contact_person_department: row["担当部署"].to_s.strip.presence,
        contact_person_name:       row["担当者名"].to_s.strip.presence,
        contact_person_email:      row["担当者メール"].to_s.strip.presence
      }.compact
    end

    def normalize_status(value)
      v = value.to_s.strip.downcase
      Customer::STATUSES.value?(v) ? v : "active"
    end
  end
end
