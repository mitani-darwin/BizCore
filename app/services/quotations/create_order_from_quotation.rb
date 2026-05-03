module Quotations
  class CreateOrderFromQuotation
    def self.call(quotation:, order_date: Date.current)
      new(quotation:, order_date:).call
    end

    def initialize(quotation:, order_date:)
      @quotation = quotation
      @order_date = order_date
    end

    def call
      quotation.transaction do
        raise ArgumentError, "見積明細がありません" if quotation.quotation_items.empty?
        raise ArgumentError, "採用済みの見積のみ注文へ変換できます" unless quotation.accepted?
        raise ArgumentError, "この見積から作成済みの注文がすでに存在します" if quotation.orders.exists?

        order = quotation.tenant.orders.create!(
          quotation: quotation,
          customer: quotation.customer,
          order_date: order_date,
          ordered_by_name: quotation.customer.primary_contact.presence,
          delivery_address: quotation.customer.full_address,
          remarks: order_remarks
        )

        quotation.quotation_items.each do |item|
          order.order_items.create!(
            tenant: quotation.tenant,
            product: item.product,
            quantity: item.quantity,
            unit_price: item.unit_price
          )
        end

        quotation.mark_as_converted!
        order
      end
    end

    private

    attr_reader :quotation, :order_date

    def order_remarks
      remarks = ["見積書 #{quotation.quotation_number} から変換"]
      remarks << quotation.subject if quotation.subject.present?
      remarks << quotation.remarks if quotation.remarks.present?
      remarks.join("\n")
    end
  end
end
