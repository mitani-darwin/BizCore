module Purchases
  # 発注書を「送信済み」に更新するサービス。PurchaseOrder#mark_as_sent! を呼び出す薄いラッパー。
  class SendPurchaseOrder
    def self.call(purchase_order:, sent_at: Time.current)
      new(purchase_order:, sent_at:).call
    end

    def initialize(purchase_order:, sent_at:)
      @purchase_order = purchase_order
      @sent_at = sent_at
    end

    def call
      purchase_order.transaction do
        raise ArgumentError, "発注明細がありません" if purchase_order.purchase_order_items.empty?

        purchase_order.mark_as_sent!(sent_at: sent_at)
      end

      purchase_order
    end

    private

    attr_reader :purchase_order, :sent_at
  end
end
