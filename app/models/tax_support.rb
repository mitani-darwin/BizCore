# 消費税計算のユーティリティモジュール。
# taxable_10（標準税率10%）/ taxable_8（軽減税率8%）/ non_taxable（非課税）の3区分を管理する。
# 端数処理は半端繰り上げ（:half_up）で行う。
module TaxSupport
  RATES = {
    "taxable_10" => BigDecimal("0.10"),
    "taxable_8" => BigDecimal("0.08"),
    "non_taxable" => BigDecimal("0")
  }.freeze

  def self.rate_for(category)
    RATES.fetch(category.to_s, BigDecimal("0"))
  end

  def self.tax_amount_for(amount, category)
    (BigDecimal(amount.to_s) * rate_for(category)).round(0, :half_up)
  end
end
