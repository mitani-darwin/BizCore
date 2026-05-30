# 請求書発行通知メーラー。
# 月次請求処理完了後に、顧客の登録メールアドレスへ発行通知を送信する。
# メール未設定の顧客はスキップされる（呼び出し元で email の有無を確認すること）。
class InvoiceMailer < ApplicationMailer
  # 請求書が発行されたことを顧客に通知する。
  def invoice_issued(invoice:)
    @invoice  = invoice
    @customer = invoice.customer
    @tenant   = invoice.tenant

    mail(
      to:      @customer.email,
      subject: "[#{@tenant.name}] 請求書を発行しました - #{@invoice.invoice_number}"
    )
  end
end
