# 契約期限アラートを日次で実行するジョブ。
# Solid Queue の recurring 設定により毎朝9時に自動実行される。
# 各テナントに対して以下を行う:
#   1. ステータスが active で満了日が過去の契約を expired に自動遷移
#   2. ALERT_THRESHOLDS 以内に期限を迎える有効な契約があれば担当者にダイジストメールを送信
class ContractExpiryAlertJob < ApplicationJob
  queue_as :default

  def perform
    Tenant.find_each do |tenant|
      process_tenant(tenant)
    end
  end

  private

  def process_tenant(tenant)
    auto_expire_contracts!(tenant)
    send_expiry_alerts(tenant)
  end

  # 満了日を過ぎた active 契約を expired に遷移させる。
  def auto_expire_contracts!(tenant)
    tenant.contracts.already_expired.find_each(&:auto_expire!)
  end

  # 期限が迫っている有効な契約をまとめて担当者に通知する。
  def send_expiry_alerts(tenant)
    alert_days = Contract::ALERT_THRESHOLDS.max
    contracts = tenant.contracts
                      .where(status: "active")
                      .expiring_within(alert_days)
                      .includes(:customer, :supplier)
                      .sort_by { |c| c.days_until_expiry || Float::INFINITY }

    return if contracts.empty?

    recipients = User.where(tenant_id: tenant.id)
                     .with_permission("admin.contracts.read")
                     .where.not(email: nil)

    recipients.each do |recipient|
      ContractAlertMailer.expiry_digest(
        tenant: tenant,
        contracts: contracts,
        recipient: recipient
      ).deliver_later
    end
  end
end
