module Admin
  class PurchaseAdjustmentsController < BaseController
    before_action :set_purchase_adjustment, only: [:show]

    def index
      @filters = {
        q: search_keyword,
        adjustment_type: search_adjustment_type,
        supplier_id: search_supplier_id
      }
      @supplier_filter_options = current_tenant.suppliers.ordered_for_admin
      @purchase_adjustments = current_tenant.purchase_adjustments
                                           .includes(:supplier, :purchase_receipt, :purchase_order)
                                           .search(search_keyword)
                                           .with_type(search_adjustment_type)
                                           .with_supplier(search_supplier_id)
                                           .ordered_for_admin
      @summary = {
        count: @purchase_adjustments.size,
        return_amount: @purchase_adjustments.select(&:purchase_return?).sum { |adjustment| adjustment.amount.to_d },
        discount_amount: @purchase_adjustments.select(&:discount?).sum { |adjustment| adjustment.amount.to_d }
      }
    end

    def show; end

    def create
      purchase_receipt = current_tenant.purchase_receipts.includes(purchase_receipt_items: :product).find_by(id: purchase_adjustment_params[:purchase_receipt_id])
      raise ActiveRecord::RecordNotFound if purchase_receipt.nil?

      adjustment = Purchases::RegisterAdjustment.call(
        purchase_receipt: purchase_receipt,
        adjustment_type: purchase_adjustment_params[:adjustment_type],
        adjustment_date: parse_date!(purchase_adjustment_params[:adjustment_date], default: Date.current),
        processed_by_name: purchase_adjustment_params[:processed_by_name].to_s.strip,
        reason: purchase_adjustment_params[:reason].to_s.strip,
        purchase_receipt_item_id: purchase_adjustment_params[:purchase_receipt_item_id],
        quantity: purchase_adjustment_params[:quantity],
        amount: purchase_adjustment_params[:amount]
      )

      audit!(
        action_key: required_permission_key,
        auditable: adjustment,
        metadata: {
          purchase_receipt_id: purchase_receipt.id,
          purchase_order_id: purchase_receipt.purchase_order_id,
          adjustment_type: adjustment.adjustment_type
        }
      )

      redirect_to admin_purchase_adjustment_path(adjustment), notice: "#{view_context.purchase_adjustment_type_label(adjustment.adjustment_type)}を登録しました。"
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_purchase_receipts_path, alert: "対象の入荷が見つかりません。"
    rescue StandardError => e
      redirect_target = purchase_receipt.present? ? admin_purchase_receipt_path(purchase_receipt) : admin_purchase_receipts_path
      redirect_to redirect_target, alert: "返品/値引き登録に失敗しました: #{e.message}"
    end

    private

    def set_purchase_adjustment
      @purchase_adjustment = current_tenant.purchase_adjustments.includes(:supplier, :purchase_receipt, :purchase_order).find_by(id: params[:id])
      return if @purchase_adjustment

      render_not_found and return false
    end

    def purchase_adjustment_params
      params.require(:purchase_adjustment).permit(
        :purchase_receipt_id,
        :purchase_receipt_item_id,
        :adjustment_type,
        :adjustment_date,
        :processed_by_name,
        :reason,
        :quantity,
        :amount
      )
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_adjustment_type
      adjustment_type = params[:adjustment_type].to_s
      PurchaseAdjustment.adjustment_types.value?(adjustment_type) ? adjustment_type : nil
    end

    def search_supplier_id
      supplier = current_tenant.suppliers.find_by(id: params[:supplier_id])
      supplier&.id
    end

    def parse_date!(raw_value, default:)
      return default if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      raise ArgumentError, "日付の形式が正しくありません"
    end
  end
end
