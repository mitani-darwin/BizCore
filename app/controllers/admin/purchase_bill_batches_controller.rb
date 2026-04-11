module Admin
  class PurchaseBillBatchesController < BaseController
    before_action :set_purchase_bill_batch, only: [:show, :cancel]

    def index
      @purchase_bill_batches = current_tenant.purchase_bill_batches.includes(:executed_by, :cancelled_by, :purchase_bills).recent
    end

    def show
      @purchase_bills = @purchase_bill_batch.purchase_bills.includes(:supplier, :supplier_payment_allocations).order(:id)
    end

    def cancel
      Purchases::CancelPurchaseBillBatch.call(
        purchase_bill_batch: @purchase_bill_batch,
        cancelled_by: current_admin_user
      )
      audit!(
        action_key: required_permission_key,
        auditable: @purchase_bill_batch,
        metadata: { purchase_bill_batch_id: @purchase_bill_batch.id, status: @purchase_bill_batch.status }
      )
      redirect_to admin_purchase_bill_batch_path(@purchase_bill_batch), notice: "仕入請求締めを解除しました。"
    rescue StandardError => e
      redirect_to admin_purchase_bill_batch_path(@purchase_bill_batch), alert: "仕入請求締め解除に失敗しました: #{e.message}"
    end

    private

    def set_purchase_bill_batch
      @purchase_bill_batch = current_tenant.purchase_bill_batches.includes(
        :executed_by,
        :cancelled_by,
        purchase_bills: [:supplier, :supplier_payment_allocations]
      ).find_by(id: params[:id])
      return if @purchase_bill_batch

      render_not_found and return false
    end
  end
end
