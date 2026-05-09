module Admin
  class PurchaseBillsController < BaseController
    before_action :set_purchase_bill, only: [ :show, :download_excel, :cancel, :reissue ]

    def index
      @purchase_bills = current_tenant.purchase_bills.includes(:supplier, :supplier_payment_allocations, :purchase_bill_batch).order(bill_date: :desc, id: :desc)
      @recent_purchase_bill_batches = current_tenant.purchase_bill_batches.includes(:executed_by, :purchase_bills).recent.limit(5)
      @billing_defaults = billing_defaults
    end

    def show; end

    def download_excel
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "purchase_bill")
      send_data(
        Purchases::ExportPurchaseBillXlsx.call(purchase_bill: @purchase_bill, template: template),
        filename: "#{@purchase_bill.bill_number}.xlsx",
        type: Reports::BaseXlsx::MIME_TYPE,
        disposition: :attachment
      )
    end

    def issue_monthly
      values = billing_values
      purchase_bill_batch = Purchases::IssueMonthlyBills.call(
        tenant: current_tenant,
        closing_date: values[:closing_date],
        billing_period_from: values[:billing_period_from],
        billing_period_to: values[:billing_period_to],
        bill_date: values[:bill_date],
        default_due_date: values[:default_due_date],
        requested_by: current_admin_user,
        note: values[:note]
      )

      audit!(
        action_key: required_permission_key,
        auditable: purchase_bill_batch,
        metadata: {
          purchase_bill_batch_id: purchase_bill_batch.id,
          purchase_bill_ids: purchase_bill_batch.purchase_bills.pluck(:id),
          closing_date: values[:closing_date],
          billing_period_from: values[:billing_period_from],
          billing_period_to: values[:billing_period_to]
        }
      )

      message =
        if purchase_bill_batch.bill_count.positive?
          "#{purchase_bill_batch.bill_count}件の仕入請求書を発行しました。"
        else
          "仕入請求対象の入荷・調整データはありませんでしたが、締め処理は記録しました。"
        end
      redirect_to admin_purchase_bill_batch_path(purchase_bill_batch), notice: message
    rescue Purchases::IssueMonthlyBills::AlreadyClosedError => e
      redirect_to admin_purchase_bills_path, alert: e.message
    rescue StandardError => e
      redirect_to admin_purchase_bills_path, alert: "月次仕入請求に失敗しました: #{e.message}"
    end

    def cancel
      Purchases::CancelPurchaseBill.call(purchase_bill: @purchase_bill, cancelled_by: current_admin_user)
      audit!(
        action_key: required_permission_key,
        auditable: @purchase_bill,
        metadata: { purchase_bill_id: @purchase_bill.id, status: @purchase_bill.status }
      )
      redirect_to admin_purchase_bill_path(@purchase_bill), notice: "仕入請求書を取消しました。"
    rescue StandardError => e
      redirect_to admin_purchase_bill_path(@purchase_bill), alert: "仕入請求取消に失敗しました: #{e.message}"
    end

    def reissue
      purchase_bill = Purchases::ReissuePurchaseBill.call(
        purchase_bill: @purchase_bill,
        bill_date: parse_date!(params[:bill_date], default: Date.current),
        default_due_date: parse_date!(params[:default_due_date], default: @purchase_bill.due_date)
      )
      audit!(
        action_key: required_permission_key,
        auditable: purchase_bill,
        metadata: { original_purchase_bill_id: @purchase_bill.id, reissued_purchase_bill_id: purchase_bill.id }
      )
      redirect_to admin_purchase_bill_path(purchase_bill), notice: "仕入請求書を再発行しました。"
    rescue StandardError => e
      redirect_to admin_purchase_bill_path(@purchase_bill), alert: "仕入請求再発行に失敗しました: #{e.message}"
    end

    private

    def set_purchase_bill
      @purchase_bill = current_tenant.purchase_bills.includes(
        :supplier,
        :purchase_bill_batch,
        :reissued_from,
        :reissues,
        purchase_bill_items: :source,
        supplier_payment_allocations: :supplier_payment
      ).find_by(id: params[:id])
      return if @purchase_bill

      render_not_found and return false
    end

    def billing_defaults
      closing_date = Date.current.end_of_month
      {
        billing_period_from: closing_date.beginning_of_month,
        billing_period_to: closing_date.end_of_month,
        closing_date: closing_date,
        bill_date: closing_date,
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
        bill_date: parse_date!(params[:bill_date], default: defaults[:bill_date]),
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
