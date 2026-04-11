module Admin
  class PurchaseOrdersController < BaseController
    MINIMUM_PURCHASE_ORDER_ITEM_ROWS = 1

    before_action :set_purchase_order, only: [:show, :edit, :update, :send_purchase_order, :receive_items]
    before_action :set_form_options, only: [:new, :create, :edit, :update]
    before_action :ensure_editable_purchase_order!, only: [:edit, :update]

    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        supplier_id: search_supplier_id
      }
      @supplier_filter_options = current_tenant.suppliers.ordered_for_admin
      @purchase_orders = current_tenant.purchase_orders
                                       .includes(:supplier, :warehouse, :purchase_order_items)
                                       .search(search_keyword)
                                       .with_status(search_status)
                                       .with_supplier(search_supplier_id)
                                       .ordered_for_admin
      @summary = {
        count: @purchase_orders.size,
        open_count: @purchase_orders.count { |purchase_order| %w[sent partially_received].include?(purchase_order.status) },
        completed_count: @purchase_orders.count(&:received?)
      }
    end

    def show
      @purchase_receipts = @purchase_order.purchase_receipts.order(received_on: :desc, id: :desc)
      @purchase_adjustments = @purchase_order.purchase_adjustments.ordered_for_admin.limit(5)
    end

    def new
      @purchase_order = current_tenant.purchase_orders.build(
        supplier_id: selected_supplier_id,
        order_date: Date.current,
        requested_delivery_date: Date.current + 7
      )
      build_purchase_order_item_rows(@purchase_order)
    end

    def create
      @purchase_order = current_tenant.purchase_orders.build(purchase_order_params)

      if @purchase_order.save
        redirect_to admin_purchase_order_path(@purchase_order), notice: "発注を作成しました。"
      else
        build_purchase_order_item_rows(@purchase_order)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_purchase_order_item_rows(@purchase_order)
    end

    def update
      if @purchase_order.update(purchase_order_params)
        redirect_to admin_purchase_order_path(@purchase_order), notice: "発注を更新しました。"
      else
        build_purchase_order_item_rows(@purchase_order)
        render :edit, status: :unprocessable_entity
      end
    end

    def send_purchase_order
      Purchases::SendPurchaseOrder.call(purchase_order: @purchase_order)
      audit!(action_key: required_permission_key, auditable: @purchase_order, metadata: { status: @purchase_order.status, sent_at: @purchase_order.sent_at })
      redirect_to admin_purchase_order_path(@purchase_order), notice: "発注書を送信しました。"
    rescue StandardError => e
      redirect_to admin_purchase_order_path(@purchase_order), alert: "発注書送信に失敗しました: #{e.message}"
    end

    def receive_items
      receipt = Purchases::ReceivePurchaseOrder.call(
        purchase_order: @purchase_order,
        received_on: parse_date!(params[:received_on], default: Date.current),
        received_by_name: params[:received_by_name].to_s.strip,
        remarks: params[:remarks].to_s.strip,
        quantities: params.fetch(:received_quantities, {}).to_unsafe_h
      )
      audit!(
        action_key: required_permission_key,
        auditable: receipt,
        metadata: {
          purchase_order_id: @purchase_order.id,
          purchase_receipt_id: receipt.id
        }
      )
      redirect_to admin_purchase_receipt_path(receipt), notice: "入荷を登録しました。"
    rescue StandardError => e
      redirect_to admin_purchase_order_path(@purchase_order), alert: "入荷登録に失敗しました: #{e.message}"
    end

    private

    def set_purchase_order
      @purchase_order = current_tenant.purchase_orders.includes(:supplier, :warehouse, purchase_order_items: :product).find_by(id: params[:id])
      return if @purchase_order

      render_not_found and return false
    end

    def set_form_options
      @supplier_options = current_tenant.suppliers.ordered_for_admin
      @warehouse_options = current_tenant.warehouses.where(active: true).order(:name)
      @product_options = current_tenant.products.order(:name)
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      PurchaseOrder.statuses.value?(status) ? status : nil
    end

    def search_supplier_id
      supplier = current_tenant.suppliers.find_by(id: params[:supplier_id])
      supplier&.id
    end

    def selected_supplier_id
      supplier = current_tenant.suppliers.find_by(id: params[:supplier_id])
      supplier&.id
    end

    def ensure_editable_purchase_order!
      return if @purchase_order.draft?

      redirect_to admin_purchase_order_path(@purchase_order), alert: "下書きの発注のみ編集できます。" and return false
    end

    def purchase_order_params
      permitted = params.require(:purchase_order).permit(
        :supplier_id,
        :warehouse_id,
        :order_date,
        :requested_delivery_date,
        :ordered_by_name,
        :remarks,
        purchase_order_items_attributes: [:id, :product_id, :quantity, :unit_cost, :_destroy]
      )

      normalize_purchase_order_item_attributes!(permitted)
      permitted
    end

    def normalize_purchase_order_item_attributes!(permitted)
      attributes = permitted[:purchase_order_items_attributes]
      return unless attributes

      permitted[:purchase_order_items_attributes] = attributes.to_h.each_with_object({}) do |(key, value), hash|
        row = value.to_h
        blank_row = row["id"].blank? &&
                    row["_destroy"] != "1" &&
                    row["product_id"].blank? &&
                    row["quantity"].blank? &&
                    row["unit_cost"].blank?
        next if blank_row

        hash[key] = row
      end
    end

    def build_purchase_order_item_rows(purchase_order)
      existing_count = purchase_order.purchase_order_items.reject(&:marked_for_destruction?).size
      [MINIMUM_PURCHASE_ORDER_ITEM_ROWS - existing_count, 0].max.times do
        purchase_order.purchase_order_items.build(tenant: current_tenant)
      end
    end

    def parse_date!(raw_value, default:)
      return default if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      raise ArgumentError, "日付の形式が正しくありません"
    end
  end
end
