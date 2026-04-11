module Admin
  module OrderingHelper
    TAX_CATEGORY_OPTIONS = [
      ["課税 10%", "taxable_10"],
      ["軽減税率 8%", "taxable_8"],
      ["非課税", "non_taxable"]
    ].freeze

    PAYMENT_METHOD_OPTIONS = [
      ["銀行振込", "bank_transfer"],
      ["口座振替", "direct_debit"],
      ["現金", "cash"],
      ["その他", "other"]
    ].freeze

    INVOICE_DELIVERY_METHOD_OPTIONS = [
      ["メール", "email"],
      ["郵送", "postal"],
      ["手渡し", "hand"]
    ].freeze

    PAYMENT_DUE_RULE_OPTIONS = [
      ["当月末", "end_of_month"],
      ["翌月末", "next_month_end"],
      ["翌々月末", "next_two_month_end"],
      ["個別設定", "custom"]
    ].freeze

    CUSTOMER_STATUS_OPTIONS = [
      ["取引中", "active"],
      ["停止", "inactive"]
    ].freeze

    SUPPLIER_STATUS_OPTIONS = [
      ["取引中", "active"],
      ["停止", "inactive"]
    ].freeze

    PURCHASE_ADJUSTMENT_TYPE_OPTIONS = [
      ["返品", "purchase_return"],
      ["値引き", "discount"]
    ].freeze

    STOCK_MOVEMENT_OPTIONS = [
      ["入庫", "inbound"],
      ["棚卸増加", "adjustment_increase"],
      ["棚卸減少", "adjustment_decrease"]
    ].freeze

    def jp_date(value)
      return "-" if value.blank?

      value.strftime("%Y/%m/%d")
    end

    def tax_category_options
      TAX_CATEGORY_OPTIONS
    end

    def payment_method_options
      PAYMENT_METHOD_OPTIONS
    end

    def invoice_delivery_method_options
      INVOICE_DELIVERY_METHOD_OPTIONS
    end

    def payment_due_rule_options
      PAYMENT_DUE_RULE_OPTIONS
    end

    def customer_status_options
      CUSTOMER_STATUS_OPTIONS
    end

    def supplier_status_options
      SUPPLIER_STATUS_OPTIONS
    end

    def purchase_adjustment_type_options
      PURCHASE_ADJUSTMENT_TYPE_OPTIONS
    end

    def stock_movement_options
      STOCK_MOVEMENT_OPTIONS
    end

    def money(value)
      number_to_currency(value.to_d, unit: "¥", precision: 0, format: "%u%n")
    end

    def order_status_badge(order)
      label, tone = order_status_tone(order.status)

      status_badge(label, tone)
    end

    def quotation_status_badge(quotation)
      label, tone = quotation_status_tone(quotation.status)

      if quotation.expiration_date.present? && quotation.expiration_date < Date.current && quotation.sent?
        label = "期限切れ"
        tone = "rose"
      end

      status_badge(label, tone)
    end

    def quotation_status_label(status)
      quotation_status_tone(status).first
    end

    def order_status_label(status)
      order_status_tone(status).first
    end

    def purchase_order_status_badge(purchase_order)
      label, tone = purchase_order_status_tone(purchase_order.status)

      status_badge(label, tone)
    end

    def purchase_order_status_label(status)
      purchase_order_status_tone(status).first
    end

    def purchase_order_item_status_label(status)
      case status
      when "pending" then "未入荷"
      when "partially_received" then "一部入荷"
      when "received" then "入荷済"
      when "cancelled" then "取消"
      else status.to_s
      end
    end

    def purchase_receipt_status_badge(receipt)
      label, tone = case receipt.status
      when "issued" then ["入荷済", "emerald"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def purchase_adjustment_type_label(value)
      case value.to_s
      when "purchase_return" then "返品"
      when "discount" then "値引き"
      else value.to_s
      end
    end

    def purchase_adjustment_status_badge(adjustment)
      label, tone = case adjustment.status
      when "issued"
        [purchase_adjustment_type_label(adjustment.adjustment_type), adjustment.purchase_return? ? "rose" : "amber"]
      when "cancelled" then ["取消", "slate"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def purchase_adjustment_signed_amount(adjustment)
      "-#{money(adjustment.amount)}"
    end

    def purchase_receipt_item_return_option_label(item)
      "#{item.product_name_snapshot} (返品可能 #{item.returnable_quantity} #{item.unit_name_snapshot})"
    end

    def order_item_status_label(status)
      case status
      when "pending" then "未処理"
      when "allocated" then "在庫確保済"
      when "delivered" then "納品済"
      when "billed" then "請求済"
      when "cancelled" then "取消"
      else status.to_s
      end
    end

    def delivery_status_badge(delivery)
      label, tone = case delivery.status
      when "issued" then ["発行済", "sky"]
      when "billed" then ["請求済", "violet"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def invoice_status_badge(invoice)
      label, tone = case invoice.status
      when "issued" then ["未入金", "amber"]
      when "partially_paid" then ["一部入金", "sky"]
      when "paid" then ["入金済", "emerald"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def billing_batch_status_badge(billing_batch)
      label, tone = case billing_batch.status
      when "issued" then ["締め済", "violet"]
      when "cancelled" then ["締め解除", "rose"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def payment_status_badge(payment)
      label, tone = case payment.status
      when "pending" then ["未消込", "amber"]
      when "partially_applied" then ["一部消込", "sky"]
      when "applied" then ["消込済", "emerald"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def customer_status_label(value)
      case value.to_s
      when "active" then "取引中"
      when "inactive" then "停止"
      else value.to_s.presence || "-"
      end
    end

    def customer_status_badge(customer)
      tone = customer.active? ? "emerald" : "slate"
      status_badge(customer_status_label(customer.status), tone)
    end

    def supplier_status_label(value)
      case value.to_s
      when "active" then "取引中"
      when "inactive" then "停止"
      else value.to_s.presence || "-"
      end
    end

    def supplier_status_badge(supplier)
      tone = supplier.active? ? "emerald" : "slate"
      status_badge(supplier_status_label(supplier.status), tone)
    end

    def active_badge(active)
      status_badge(active ? "有効" : "停止", active ? "emerald" : "slate")
    end

    def tax_category_label(value)
      TAX_CATEGORY_OPTIONS.to_h.invert.fetch(value, value.to_s)
    end

    def payment_method_label(value)
      PAYMENT_METHOD_OPTIONS.to_h.invert.fetch(value, value.to_s.presence || "-")
    end

    def invoice_delivery_method_label(value)
      INVOICE_DELIVERY_METHOD_OPTIONS.to_h.invert.fetch(value, value.to_s.presence || "-")
    end

    def payment_due_rule_label(value)
      PAYMENT_DUE_RULE_OPTIONS.to_h.invert.fetch(value, value.to_s.presence || "-")
    end

    def stock_movement_label(value)
      case value.to_s
      when "inbound" then "入庫"
      when "outbound" then "出庫"
      when "adjustment" then "調整"
      when "adjustment_increase" then "棚卸増加"
      when "adjustment_decrease" then "棚卸減少"
      else value.to_s
      end
    end

    def stock_movement_badge(movement)
      label, tone = case movement.movement_type
      when "inbound" then ["入庫", "emerald"]
      when "outbound" then ["出庫", "rose"]
      when "adjustment", "adjustment_increase" then ["増加調整", "sky"]
      when "adjustment_decrease" then ["減少調整", "amber"]
      else ["不明", "slate"]
      end

      status_badge(label, tone)
    end

    def stock_alert_badge(stock_item)
      if stock_item.low_stock?
        status_badge("安全在庫割れ", "rose")
      else
        status_badge("適正", "emerald")
      end
    end

    def signed_stock_quantity(value)
      quantity = value.to_i
      return "+#{quantity}" if quantity.positive?

      quantity.to_s
    end

    def stock_count_adjustment_badge(stock_count)
      adjustment = stock_count.adjustment_quantity.to_i
      return status_badge("差異なし", "slate") if adjustment.zero?

      tone = adjustment.positive? ? "sky" : "amber"
      status_badge(signed_stock_quantity(adjustment), tone)
    end

    def stock_item_option_label(stock_item)
      "#{stock_item.warehouse.name} / #{stock_item.product.name} (在庫 #{stock_item.quantity_on_hand}, 利用可能 #{stock_item.available_quantity})"
    end

    private

    def quotation_status_tone(status)
      case status
      when "draft" then ["下書き", "slate"]
      when "sent" then ["提示済", "sky"]
      when "accepted" then ["採用", "emerald"]
      when "converted" then ["注文変換済", "violet"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end
    end

    def purchase_order_status_tone(status)
      case status
      when "draft" then ["下書き", "slate"]
      when "sent" then ["発注済", "sky"]
      when "partially_received" then ["一部入荷", "amber"]
      when "received" then ["入荷完了", "emerald"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end
    end

    def order_status_tone(status)
      case status
      when "draft" then ["下書き", "slate"]
      when "sent" then ["送信済", "sky"]
      when "accepted" then ["受注済", "indigo"]
      when "allocated" then ["在庫確保済", "amber"]
      when "delivered" then ["納品済", "emerald"]
      when "billed" then ["請求済", "violet"]
      when "cancelled" then ["取消", "rose"]
      else ["不明", "slate"]
      end
    end

    def status_badge(label, tone)
      tag.span(
        label,
        class: "inline-flex items-center rounded-full border border-#{tone}-200 bg-#{tone}-50 px-2.5 py-1 text-xs font-semibold text-#{tone}-700"
      )
    end
  end
end
