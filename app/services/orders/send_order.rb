module Orders
  class SendOrder
    def self.call(order:, sent_at: Time.current)
      new(order:, sent_at:).call
    end

    def initialize(order:, sent_at:)
      @order = order
      @sent_at = sent_at
    end

    def call
      order.transaction do
        raise ArgumentError, "order has no items" if order.order_items.empty?

        order.order_items.each do |item|
          item.update!(status: "pending") if item.pending?
        end

        order.mark_as_sent!(sent_at: sent_at)
      end

      order
    end

    private

    attr_reader :order, :sent_at
  end
end
