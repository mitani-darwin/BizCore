# 在庫アラートメールを非同期送信するジョブ。
# StockItem の在庫が安全在庫を下回る閾値越えを検出した際にエンキューされる。
# ジョブ実行時に再度 low_stock? を確認し、既に補充済みであればスキップする。
class StockAlertJob < ApplicationJob
  queue_as :default

  def perform(stock_item_id)
    stock_item = StockItem.includes(:product, :warehouse, :tenant).find_by(id: stock_item_id)
    return unless stock_item&.low_stock?

    recipients = User.where(tenant_id: stock_item.tenant_id)
                     .with_permission("admin.stock_items.read")
                     .where.not(email: nil)

    recipients.each do |recipient|
      StockAlertMailer.low_stock_alert(stock_item: stock_item, recipient: recipient).deliver_later
    end
  end
end
