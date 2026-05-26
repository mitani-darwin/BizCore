module Admin
  class InvoicesController < BaseController
    before_action :set_invoice, only: [ :show, :download_excel, :download_pdf, :cancel, :reissue ]

    def index
      @pagy, @invoices = pagy(current_tenant.invoices.includes(:customer, :payment_allocations, :billing_batch).order(invoice_date: :desc, id: :desc))
      @recent_billing_batches = current_tenant.billing_batches.includes(:executed_by, :invoices).recent.limit(5)
      @billing_defaults = billing_defaults
    end

    def show; end

    def download_excel
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "invoice")
      send_data(
        Invoicing::ExportInvoiceXlsx.call(invoice: @invoice, template: template),
        filename: "#{@invoice.invoice_number}.xlsx",
        type: Reports::BaseXlsx::MIME_TYPE,
        disposition: :attachment
      )
    end

    def download_pdf
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "invoice")
      send_data(
        Invoicing::ExportInvoicePdf.call(invoice: @invoice, template: template),
        filename: "#{@invoice.invoice_number}.pdf",
        type: Reports::BasePdf::MIME_TYPE,
        disposition: :attachment
      )
    end

    def issue_monthly
      values = billing_values
      billing_batch = Invoicing::IssueMonthlyInvoices.call(
        tenant: current_tenant,
        closing_date: values[:closing_date],
        billing_period_from: values[:billing_period_from],
        billing_period_to: values[:billing_period_to],
        invoice_date: values[:invoice_date],
        default_due_date: values[:default_due_date],
        requested_by: current_admin_user,
        note: values[:note]
      )

      audit!(
        action_key: required_permission_key,
        auditable: billing_batch,
        metadata: {
          billing_batch_id: billing_batch.id,
          invoice_ids: billing_batch.invoices.pluck(:id),
          closing_date: values[:closing_date],
          billing_period_from: values[:billing_period_from],
          billing_period_to: values[:billing_period_to]
        }
      )

      message = billing_batch.invoice_count.positive? ? "#{billing_batch.invoice_count}件の請求書を発行しました。" : "請求対象の納品データはありませんでしたが、締め処理は記録しました。"
      redirect_to admin_billing_batch_path(billing_batch), notice: message
    rescue Invoicing::IssueMonthlyInvoices::AlreadyClosedError => e
      redirect_to admin_invoices_path, alert: e.message
    rescue StandardError => e
      redirect_to admin_invoices_path, alert: "月末請求に失敗しました: #{e.message}"
    end

    def cancel
      Invoicing::CancelInvoice.call(invoice: @invoice, cancelled_by: current_admin_user)
      audit!(
        action_key: required_permission_key,
        auditable: @invoice,
        metadata: { invoice_id: @invoice.id, status: @invoice.status }
      )
      redirect_to admin_invoice_path(@invoice), notice: "請求書を取消しました。"
    rescue StandardError => e
      redirect_to admin_invoice_path(@invoice), alert: "請求取消に失敗しました: #{e.message}"
    end

    def reissue
      invoice = Invoicing::ReissueInvoice.call(
        invoice: @invoice,
        invoice_date: parse_date!(params[:invoice_date], default: Date.current),
        default_due_date: parse_date!(params[:default_due_date], default: @invoice.due_date)
      )
      audit!(
        action_key: required_permission_key,
        auditable: invoice,
        metadata: { original_invoice_id: @invoice.id, reissued_invoice_id: invoice.id }
      )
      redirect_to admin_invoice_path(invoice), notice: "請求書を再発行しました。"
    rescue StandardError => e
      redirect_to admin_invoice_path(@invoice), alert: "請求再発行に失敗しました: #{e.message}"
    end

    private

    def set_invoice
      @invoice = current_tenant.invoices.includes(:customer, :billing_batch, :reissued_from, :reissues, invoice_items: :source, payment_allocations: :payment).find_by(id: params[:id])
      return if @invoice

      render_not_found and return false
    end

    def billing_defaults
      closing_date = Date.current.end_of_month
      {
        billing_period_from: closing_date.beginning_of_month,
        billing_period_to: closing_date.end_of_month,
        closing_date: closing_date,
        invoice_date: closing_date,
        default_due_date: closing_date.next_month.end_of_month,
        note: nil
      }
    end

    def billing_values
      defaults = billing_defaults
      {
        billing_period_from: parse_date!(params[:billing_period_from], default: defaults[:billing_period_from]),
        billing_period_to: parse_date!(params[:billing_period_to], default: defaults[:billing_period_to]),
        closing_date: parse_date!(params[:closing_date], default: defaults[:closing_date]),
        invoice_date: parse_date!(params[:invoice_date], default: defaults[:invoice_date]),
        default_due_date: parse_date!(params[:default_due_date], default: defaults[:default_due_date]),
        note: params[:note].to_s.strip.presence
      }
    end

    def parse_date!(raw_value, default:)
      return default if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      raise ArgumentError, "日付の形式が正しくありません"
    end
  end
end
