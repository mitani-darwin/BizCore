module Admin
  module ContractsHelper
    include Admin::OrderingHelper
    CONTRACT_STATUS_OPTIONS = [
      [ "下書き",     "draft" ],
      [ "有効",       "active" ],
      [ "期限切れ",   "expired" ],
      [ "解約",       "cancelled" ]
    ].freeze

    CONTRACT_COUNTERPARTY_TYPE_OPTIONS = [
      [ "得意先契約", "customer" ],
      [ "仕入先契約", "supplier" ],
      [ "その他",     "other" ]
    ].freeze

    def contract_status_options
      CONTRACT_STATUS_OPTIONS
    end

    def contract_counterparty_type_options
      CONTRACT_COUNTERPARTY_TYPE_OPTIONS
    end

    def contract_status_label(status)
      CONTRACT_STATUS_OPTIONS.find { |_, v| v == status.to_s }&.first || status.to_s
    end

    def contract_counterparty_type_label(type)
      CONTRACT_COUNTERPARTY_TYPE_OPTIONS.find { |_, v| v == type.to_s }&.first || type.to_s
    end

    def contract_status_badge(contract)
      label, tone = case contract.status
      when "draft"     then [ "下書き",   "slate" ]
      when "active"    then [ "有効",     "emerald" ]
      when "expired"   then [ "期限切れ", "rose" ]
      when "cancelled" then [ "解約",     "slate" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end

    def contract_counterparty_type_badge(contract)
      label, tone = case contract.counterparty_type
      when "customer" then [ "得意先", "sky" ]
      when "supplier" then [ "仕入先", "violet" ]
      when "other"    then [ "その他", "slate" ]
      else [ "不明", "slate" ]
      end

      status_badge(label, tone)
    end
  end
end
