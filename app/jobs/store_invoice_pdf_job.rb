# 請求書 PDF を Active Storage（本番: S3）に非同期で保存するジョブ。
# 電子帳簿保存法の要件に基づき、発行時に PDF を自動的に永続化する。
# 既に保存済みの場合はスキップする（再実行しても安全）。
class StoreInvoicePdfJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    return unless invoice
    return if invoice.stored_pdf.attached?

    template = DocumentTemplate.for_tenant_and_type(invoice.tenant, "invoice")
    pdf_data = Invoicing::ExportInvoicePdf.call(invoice: invoice, template: template)

    invoice.stored_pdf.attach(
      io: StringIO.new(pdf_data),
      filename: "#{invoice.invoice_number}.pdf",
      content_type: "application/pdf"
    )
  rescue => e
    Rails.logger.error("[StoreInvoicePdfJob] invoice##{invoice_id}: #{e.class} #{e.message}")
    raise
  end
end
