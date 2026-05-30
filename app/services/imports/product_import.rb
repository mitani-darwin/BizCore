module Imports
  # 商品マスタの CSV 一括インポート。
  # 商品コードが既存の場合は更新、なければ新規作成する。
  class ProductImport < BaseImport
    HEADERS = {
      code:           "商品コード",
      name:           "商品名",
      unit_name:      "単位",
      standard_price: "標準単価",
      tax_category:   "税区分(taxable_10/taxable_8/non_taxable)",
      note:           "備考"
    }.freeze

    SAMPLE_ROWS = [
      [ "PRD001", "ノートPC A モデル", "台", "80000", "taxable_10", "エントリーモデル" ],
      [ "PRD002", "有機野菜セット",     "箱", "3500",  "taxable_8",  "旬の野菜詰め合わせ" ]
    ].freeze

    TAX_CATEGORIES = %w[taxable_10 taxable_8 non_taxable].freeze

    private

    def import_row(row, _line_number)
      code = row["商品コード"].to_s.strip
      return { ok: false, errors: [ "商品コードは必須です" ] } if code.blank?

      product = tenant.products.find_or_initialize_by(code: code)
      product.assign_attributes(build_attrs(row))

      if product.save
        { ok: true }
      else
        { ok: false, errors: model_errors_to_array(product) }
      end
    end

    def build_attrs(row)
      {
        name:           row["商品名"].to_s.strip.presence,
        unit_name:      row["単位"].to_s.strip.presence,
        standard_price: parse_decimal(row["標準単価"]),
        tax_category:   normalize_tax_category(row["税区分(taxable_10/taxable_8/non_taxable)"]),
        note:           row["備考"].to_s.strip.presence
      }.compact
    end

    def normalize_tax_category(value)
      v = value.to_s.strip.downcase
      TAX_CATEGORIES.include?(v) ? v : "taxable_10"
    end

    def parse_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s.gsub(/[,，]/, "").strip)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
