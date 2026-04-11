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
    (BigDecimal(amount.to_s) * rate_for(category)).round(2)
  end
end
