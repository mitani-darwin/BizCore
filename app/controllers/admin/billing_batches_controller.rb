module Admin
  # 請求締めバッチの一覧・詳細・締め解除を管理する。
  # cancel は Invoicing::CancelBillingBatch サービスを呼び、一括でキャンセル処理を行う。
  class BillingBatchesController < BaseController
    before_action :set_billing_batch, only: [ :show, :cancel ]

    def index
      @pagy, @billing_batches = pagy(current_tenant.billing_batches.includes(:executed_by, :cancelled_by, :invoices).recent)
    end

    def show
      @invoices = @billing_batch.invoices.includes(:customer, :payment_allocations).order(:id)
    end

    def cancel
      Invoicing::CancelBillingBatch.call(
        billing_batch: @billing_batch,
        cancelled_by: current_admin_user
      )
      audit!(
        action_key: required_permission_key,
        auditable: @billing_batch,
        metadata: { billing_batch_id: @billing_batch.id, status: @billing_batch.status }
      )
      redirect_to admin_billing_batch_path(@billing_batch), notice: "請求締めを解除しました。"
    rescue StandardError => e
      redirect_to admin_billing_batch_path(@billing_batch), alert: "請求締め解除に失敗しました: #{e.message}"
    end

    private

    def set_billing_batch
      @billing_batch = current_tenant.billing_batches.includes(:executed_by, :cancelled_by, invoices: [ :customer, :payment_allocations ]).find_by(id: params[:id])
      return if @billing_batch

      render_not_found and return false
    end
  end
end
