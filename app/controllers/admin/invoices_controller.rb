module Admin
  class InvoicesController < BaseController
    before_action :set_invoice, only: [:show]

    def index
      @invoices = current_tenant.invoices.includes(:customer, :payment_allocations).order(invoice_date: :desc, id: :desc)
      @billing_defaults = billing_defaults
    end

    def show; end

    def issue_monthly
      values = billing_values
      invoices = Invoicing::IssueMonthlyInvoices.call(
        tenant: current_tenant,
        closing_date: values[:closing_date],
        billing_period_from: values[:billing_period_from],
        billing_period_to: values[:billing_period_to],
        invoice_date: values[:invoice_date],
        due_date: values[:due_date]
      )

      audit!(
        action_key: required_permission_key,
        auditable: invoices.last,
        metadata: {
          invoice_ids: invoices.map(&:id),
          closing_date: values[:closing_date],
          billing_period_from: values[:billing_period_from],
          billing_period_to: values[:billing_period_to]
        }
      )

      message = invoices.any? ? "#{invoices.size}件の請求書を発行しました。" : "請求対象の納品データはありませんでした。"
      redirect_to admin_invoices_path, notice: message
    rescue StandardError => e
      redirect_to admin_invoices_path, alert: "月末請求に失敗しました: #{e.message}"
    end

    private

    def set_invoice
      @invoice = current_tenant.invoices.includes(:customer, :invoice_items, payment_allocations: :payment).find_by(id: params[:id])
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
        due_date: closing_date.next_month.end_of_month
      }
    end

    def billing_values
      defaults = billing_defaults
      {
        billing_period_from: parse_date!(params[:billing_period_from], default: defaults[:billing_period_from]),
        billing_period_to: parse_date!(params[:billing_period_to], default: defaults[:billing_period_to]),
        closing_date: parse_date!(params[:closing_date], default: defaults[:closing_date]),
        invoice_date: parse_date!(params[:invoice_date], default: defaults[:invoice_date]),
        due_date: parse_date!(params[:due_date], default: defaults[:due_date])
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
