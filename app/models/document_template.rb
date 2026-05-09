class DocumentTemplate < ApplicationRecord
  belongs_to :tenant

  DOCUMENT_TYPES = %w[invoice order quotation delivery purchase_order purchase_bill purchase_receipt].freeze

  DEFINITIONS = {
    "invoice" => {
      title: "請求書",
      column_widths: [ 24, 10, 12, 12, 12, 14 ],
      rows: [
        { key: "customer_payment", label: "得意先・支払期日・請求締め" },
        { key: "delivery_terms", label: "送付方法・支払条件・締日" },
        { key: "contact_info", label: "得意先担当者・連絡先" },
        { key: "billing_period", label: "請求期間" },
        { key: "address", label: "請求先住所" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "description", default_label: "内容" },
        { key: "quantity", default_label: "数量" },
        { key: "unit_price", default_label: "単価" },
        { key: "tax_category", default_label: "税区分" },
        { key: "tax_amount", default_label: "税額" },
        { key: "amount", default_label: "金額" }
      ]
    },
    "order" => {
      title: "注文書",
      column_widths: [ 14, 26, 10, 12, 14, 10, 10, 14 ],
      rows: [
        { key: "customer_delivery", label: "得意先・希望納期・先方担当者" },
        { key: "contact_info", label: "得意先担当者・連絡先" },
        { key: "delivery_address", label: "納品先住所" },
        { key: "remarks", label: "備考" },
        { key: "source_quotation", label: "元見積" }
      ],
      item_columns: [
        { key: "product_code", default_label: "商品コード" },
        { key: "product_name", default_label: "商品名" },
        { key: "quantity", default_label: "数量" },
        { key: "unit_price", default_label: "単価" },
        { key: "amount", default_label: "金額" },
        { key: "allocated", default_label: "引当" },
        { key: "delivered", default_label: "納品" },
        { key: "status", default_label: "状態" }
      ]
    },
    "quotation" => {
      title: "見積書",
      column_widths: [ 18, 28, 12, 14, 14, 16 ],
      rows: [
        { key: "customer_expiry", label: "得意先・有効期限・担当者" },
        { key: "subject", label: "件名" },
        { key: "contact_info", label: "得意先担当者・連絡先" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "product_code", default_label: "商品コード" },
        { key: "product_name", default_label: "商品名" },
        { key: "quantity", default_label: "数量" },
        { key: "unit_price", default_label: "単価" },
        { key: "tax_amount", default_label: "税額" },
        { key: "amount", default_label: "金額" }
      ]
    },
    "delivery" => {
      title: "納品書",
      column_widths: [ 14, 26, 10, 12, 12, 14 ],
      rows: [
        { key: "customer_order", label: "得意先・注文番号・発行日時" },
        { key: "contact_info", label: "得意先担当者・連絡先" },
        { key: "delivery_address", label: "納品先住所" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "product_code", default_label: "商品コード" },
        { key: "product_name", default_label: "商品名" },
        { key: "quantity", default_label: "数量" },
        { key: "unit_price", default_label: "単価" },
        { key: "tax_category", default_label: "税区分" },
        { key: "amount", default_label: "金額" }
      ]
    },
    "purchase_order" => {
      title: "発注書",
      column_widths: [ 14, 24, 10, 10, 10, 12, 14, 14 ],
      rows: [
        { key: "supplier_delivery", label: "仕入先・希望納期・発注担当者" },
        { key: "contact_info", label: "仕入先担当者・連絡先" },
        { key: "warehouse", label: "入荷倉庫" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "product_code", default_label: "商品コード" },
        { key: "product_name", default_label: "商品名" },
        { key: "quantity", default_label: "発注数量" },
        { key: "received", default_label: "入荷済" },
        { key: "remaining", default_label: "残数量" },
        { key: "unit_cost", default_label: "単価" },
        { key: "amount", default_label: "金額" },
        { key: "status", default_label: "状態" }
      ]
    },
    "purchase_bill" => {
      title: "仕入請求書",
      column_widths: [ 24, 10, 12, 12, 12, 14 ],
      rows: [
        { key: "supplier_payment", label: "仕入先・支払期日・仕入締め" },
        { key: "payment_terms", label: "支払方法・支払条件・締日" },
        { key: "contact_info", label: "仕入先担当者・連絡先" },
        { key: "billing_period", label: "請求期間" },
        { key: "address", label: "仕入先住所" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "description", default_label: "内容" },
        { key: "quantity", default_label: "数量" },
        { key: "unit_price", default_label: "単価" },
        { key: "tax_category", default_label: "税区分" },
        { key: "tax_amount", default_label: "税額" },
        { key: "amount", default_label: "金額" }
      ]
    },
    "purchase_receipt" => {
      title: "入荷票",
      column_widths: [ 14, 24, 10, 10, 10, 12, 14 ],
      rows: [
        { key: "supplier_order", label: "仕入先・発注番号・倉庫" },
        { key: "staff_info", label: "入荷担当者・登録日時・仕入先担当者" },
        { key: "remarks", label: "備考" }
      ],
      item_columns: [
        { key: "product_code", default_label: "商品コード" },
        { key: "product_name", default_label: "商品名" },
        { key: "quantity", default_label: "入荷数量" },
        { key: "returned", default_label: "返品済" },
        { key: "returnable", default_label: "返品可能" },
        { key: "unit_cost", default_label: "単価" },
        { key: "amount", default_label: "金額" }
      ]
    }
  }.freeze

  serialize :settings, coder: JSON

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :document_type, uniqueness: { scope: :tenant_id }

  def self.for_tenant_and_type(tenant, document_type)
    find_or_create_by!(tenant: tenant, document_type: document_type.to_s) do |t|
      t.settings = default_settings(document_type.to_s)
    end
  end

  def self.default_settings(document_type)
    defn = DEFINITIONS[document_type.to_s] || {}
    {
      "company_header_enabled" => false,
      "company_name" => "",
      "company_postal_code" => "",
      "company_address" => "",
      "company_tel" => "",
      "company_email" => "",
      "column_widths" => (defn[:column_widths] || []).dup,
      "row_visibility" => (defn[:rows] || []).each_with_object({}) { |r, h| h[r[:key]] = true },
      "item_column_labels" => (defn[:item_columns] || []).each_with_object({}) { |c, h| h[c[:key]] = c[:default_label] }
    }
  end

  def definition
    DEFINITIONS[document_type] || {}
  end

  def row_visible?(key)
    val = (settings || {}).dig("row_visibility", key.to_s)
    val.nil? ? true : val != false
  end

  def item_column_label(key, default_label)
    label = (settings || {}).dig("item_column_labels", key.to_s)
    label.present? ? label : default_label
  end

  def resolved_column_widths
    stored = (settings || {})["column_widths"]
    defaults = definition[:column_widths] || []
    return defaults unless stored.is_a?(Array) && stored.length == defaults.length
    stored.map(&:to_i)
  end

  def company_header_enabled?
    (settings || {})["company_header_enabled"] == true
  end

  def company_name
    (settings || {})["company_name"].to_s
  end

  def company_postal_code
    (settings || {})["company_postal_code"].to_s
  end

  def company_address
    (settings || {})["company_address"].to_s
  end

  def company_tel
    (settings || {})["company_tel"].to_s
  end

  def company_email
    (settings || {})["company_email"].to_s
  end
end
