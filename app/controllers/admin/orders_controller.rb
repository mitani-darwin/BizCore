module Admin
  class OrdersController < BaseController
    MINIMUM_ORDER_ITEM_ROWS = 1

    before_action :set_order, only: [ :show, :edit, :update, :download_excel, :download_pdf, :send_order, :accept_order, :reserve_stock, :issue_delivery ]
    before_action :set_form_options, only: [ :new, :create, :edit, :update ]
    before_action :ensure_editable_order!, only: [ :edit, :update ]

    def index
      @orders = current_tenant.orders.includes(:customer, :order_items).order(order_date: :desc, id: :desc)
    end

    def show
      @warehouse_options = current_tenant.warehouses.where(active: true).order(:name)
      @deliveries = @order.deliveries.order(delivery_date: :desc, id: :desc)
    end

    def new
      @order = current_tenant.orders.build(
        order_date: Date.current,
        requested_delivery_date: Date.current
      )
      build_order_item_rows(@order)
    end

    def create
      @order = current_tenant.orders.build(order_params)

      if @order.save
        redirect_to admin_order_path(@order), notice: "注文を作成しました。"
      else
        build_order_item_rows(@order)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_order_item_rows(@order)
    end

    def update
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "注文を更新しました。"
      else
        build_order_item_rows(@order)
        render :edit, status: :unprocessable_entity
      end
    end

    def download_excel
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "order")
      send_data(
        Orders::ExportXlsx.call(order: @order, template: template),
        filename: "#{@order.order_number}.xlsx",
        type: Reports::BaseXlsx::MIME_TYPE,
        disposition: :attachment
      )
    end

    def download_pdf
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "order")
      send_data(
        Orders::ExportPdf.call(order: @order, template: template),
        filename: "#{@order.order_number}.pdf",
        type: Reports::BasePdf::MIME_TYPE,
        disposition: :attachment
      )
    end

    def send_order
      Orders::SendOrder.call(order: @order)
      audit!(action_key: required_permission_key, auditable: @order, metadata: { status: @order.status, sent_at: @order.sent_at })
      redirect_to admin_order_path(@order), notice: "注文書を送信しました。"
    rescue StandardError => e
      redirect_to admin_order_path(@order), alert: "注文書の送信に失敗しました: #{e.message}"
    end

    def accept_order
      @order.mark_as_accepted!
      audit!(action_key: required_permission_key, auditable: @order, metadata: { status: @order.status, accepted_at: @order.accepted_at })
      redirect_to admin_order_path(@order), notice: "受注を確定しました。"
    rescue StandardError => e
      redirect_to admin_order_path(@order), alert: "受注確定に失敗しました: #{e.message}"
    end

    def reserve_stock
      warehouse = current_tenant.warehouses.find_by(id: params[:warehouse_id])
      raise ArgumentError, "倉庫を選択してください" if warehouse.nil?

      Inventory::ReserveOrder.call(order: @order, warehouse: warehouse)
      audit!(action_key: required_permission_key, auditable: @order, metadata: { warehouse_id: warehouse.id, status: @order.reload.status })
      redirect_to admin_order_path(@order), notice: "在庫を確保しました。"
    rescue StandardError => e
      redirect_to admin_order_path(@order), alert: "在庫確保に失敗しました: #{e.message}"
    end

    def issue_delivery
      delivery = Deliveries::IssueFromOrder.call(order: @order, delivery_date: parse_date!(params[:delivery_date], default: Date.current))
      audit!(action_key: required_permission_key, auditable: delivery, metadata: { order_id: @order.id, delivery_id: delivery.id })
      redirect_to admin_delivery_path(delivery), notice: "納品書を発行しました。"
    rescue StandardError => e
      redirect_to admin_order_path(@order), alert: "納品書発行に失敗しました: #{e.message}"
    end

    private

    def set_order
      @order = current_tenant.orders.includes(:quotation, order_items: [ product: [], stock_allocations: :warehouse ]).find_by(id: params[:id])
      return if @order

      render_not_found and return false
    end

    def set_form_options
      @customer_options = current_tenant.customers.order(:name)
      @product_options = current_tenant.products.order(:name)
    end

    def ensure_editable_order!
      return if @order.draft?

      redirect_to admin_order_path(@order), alert: "下書きの注文のみ編集できます。" and return false
    end

    def order_params
      permitted = params.require(:order).permit(
        :customer_id,
        :order_date,
        :requested_delivery_date,
        :ordered_by_name,
        :delivery_address,
        :remarks,
        order_items_attributes: [ :id, :product_id, :quantity, :unit_price, :_destroy ]
      )

      normalize_order_item_attributes!(permitted)
      permitted
    end

    def normalize_order_item_attributes!(permitted)
      attributes = permitted[:order_items_attributes]
      return unless attributes

      permitted[:order_items_attributes] = attributes.to_h.each_with_object({}) do |(key, value), hash|
        row = value.to_h
        blank_row = row["id"].blank? &&
                    row["_destroy"] != "1" &&
                    row["product_id"].blank? &&
                    row["quantity"].blank? &&
                    row["unit_price"].blank?
        next if blank_row

        hash[key] = row
      end
    end

    def build_order_item_rows(order)
      existing_count = order.order_items.reject(&:marked_for_destruction?).size
      [ MINIMUM_ORDER_ITEM_ROWS - existing_count, 0 ].max.times do
        order.order_items.build(tenant: current_tenant)
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
