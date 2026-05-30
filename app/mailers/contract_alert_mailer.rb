# 契約期限アラートを関係者に送信するメーラー。
# ContractExpiryAlertJob の日次実行から呼び出される。
class ContractAlertMailer < ApplicationMailer
  # テナント内で期限が迫っている契約のダイジストを送る。
  # contracts は残日数でソート済みの Contract の配列を想定する。
  def expiry_digest(tenant:, contracts:, recipient:)
    @tenant     = tenant
    @contracts  = contracts
    @recipient  = recipient

    mail(
      to:      recipient.email,
      subject: "[#{tenant.name}] 契約期限アラート（#{contracts.size}件）"
    )
  end
end
