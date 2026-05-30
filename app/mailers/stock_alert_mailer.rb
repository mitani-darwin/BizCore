# 在庫アラートを関係者に送信するメーラー。
# 安全在庫を下回った際に StockAlertJob から呼び出される。
class StockAlertMailer < ApplicationMailer
  # 安全在庫を下回った商品の補充を促す通知を送る。
  def low_stock_alert(stock_item:, recipient:)
    @stock_item = stock_item
    @product    = stock_item.product
    @warehouse  = stock_item.warehouse
    @tenant     = stock_item.tenant
    @recipient  = recipient

    subject_tag = stock_item.out_of_stock? ? "【在庫切れ】" : "【在庫不足】"
    mail(
      to:      recipient.email,
      subject: "#{subject_tag} #{@product.name}（#{@warehouse.name}） - #{@tenant.name}"
    )
  end
end
