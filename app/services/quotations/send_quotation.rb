module Quotations
  # 見積書を「送信済み」に更新するサービス。Quotation#mark_as_sent! を呼び出す薄いラッパー。
  class SendQuotation
    def self.call(quotation:, sent_at: Time.current)
      new(quotation:, sent_at:).call
    end

    def initialize(quotation:, sent_at:)
      @quotation = quotation
      @sent_at = sent_at
    end

    def call
      quotation.transaction do
        raise ArgumentError, "見積明細がありません" if quotation.quotation_items.empty?

        quotation.mark_as_sent!(sent_at: sent_at)
      end

      quotation
    end

    private

    attr_reader :quotation, :sent_at
  end
end
