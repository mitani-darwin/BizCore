module Admin
  class QuotationsController < BaseController
    MINIMUM_QUOTATION_ITEM_ROWS = 1

    before_action :set_quotation, only: [ :show, :edit, :update, :download_excel, :send_quotation, :accept_quotation, :create_order ]
    before_action :set_form_options, only: [ :new, :create, :edit, :update ]
    before_action :ensure_editable_quotation!, only: [ :edit, :update ]

    def index
      @quotations = current_tenant.quotations.includes(:customer, :quotation_items, :orders).order(quotation_date: :desc, id: :desc)
    end

    def show
      @orders = @quotation.orders.order(order_date: :desc, id: :desc)
    end

    def new
      @quotation = current_tenant.quotations.build(
        quotation_date: Date.current,
        expiration_date: Date.current + 30
      )
      build_quotation_item_rows(@quotation)
    end

    def create
      @quotation = current_tenant.quotations.build(quotation_params)

      if @quotation.save
        redirect_to admin_quotation_path(@quotation), notice: "見積を作成しました。"
      else
        build_quotation_item_rows(@quotation)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_quotation_item_rows(@quotation)
    end

    def update
      if @quotation.update(quotation_params)
        redirect_to admin_quotation_path(@quotation), notice: "見積を更新しました。"
      else
        build_quotation_item_rows(@quotation)
        render :edit, status: :unprocessable_entity
      end
    end

    def download_excel
      send_data(
        Quotations::ExportXlsx.call(quotation: @quotation),
        filename: "#{@quotation.quotation_number}.xlsx",
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        disposition: :attachment
      )
    end

    def send_quotation
      Quotations::SendQuotation.call(quotation: @quotation)
      audit!(action_key: required_permission_key, auditable: @quotation, metadata: { status: @quotation.status, sent_at: @quotation.sent_at })
      redirect_to admin_quotation_path(@quotation), notice: "見積書を送信しました。"
    rescue StandardError => e
      redirect_to admin_quotation_path(@quotation), alert: "見積書送信に失敗しました: #{e.message}"
    end

    def accept_quotation
      @quotation.mark_as_accepted!
      audit!(action_key: required_permission_key, auditable: @quotation, metadata: { status: @quotation.status, accepted_at: @quotation.accepted_at })
      redirect_to admin_quotation_path(@quotation), notice: "見積の採用を記録しました。"
    rescue StandardError => e
      redirect_to admin_quotation_path(@quotation), alert: "見積採用の記録に失敗しました: #{e.message}"
    end

    def create_order
      authorize!(Permissions::Catalog.admin_key(:orders, :create))
      order = Quotations::CreateOrderFromQuotation.call(quotation: @quotation)
      audit!(action_key: required_permission_key, auditable: order, metadata: { quotation_id: @quotation.id, order_id: order.id })
      redirect_to admin_order_path(order), notice: "見積から注文を作成しました。"
    rescue StandardError => e
      redirect_to admin_quotation_path(@quotation), alert: "注文変換に失敗しました: #{e.message}"
    end

    private

    def set_quotation
      @quotation = current_tenant.quotations.includes(quotation_items: :product, orders: :customer).find_by(id: params[:id])
      return if @quotation

      render_not_found and return false
    end

    def set_form_options
      @customer_options = current_tenant.customers.ordered_for_admin
      @product_options = current_tenant.products.order(:name)
    end

    def ensure_editable_quotation!
      return if @quotation.draft?

      redirect_to admin_quotation_path(@quotation), alert: "下書きの見積のみ編集できます。" and return false
    end

    def quotation_params
      permitted = params.require(:quotation).permit(
        :customer_id,
        :subject,
        :quoted_by_name,
        :quotation_date,
        :expiration_date,
        :remarks,
        quotation_items_attributes: [ :id, :product_id, :quantity, :unit_price, :_destroy ]
      )

      normalize_quotation_item_attributes!(permitted)
      permitted
    end

    def normalize_quotation_item_attributes!(permitted)
      attributes = permitted[:quotation_items_attributes]
      return unless attributes

      permitted[:quotation_items_attributes] = attributes.to_h.each_with_object({}) do |(key, value), hash|
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

    def build_quotation_item_rows(quotation)
      existing_count = quotation.quotation_items.reject(&:marked_for_destruction?).size
      [ MINIMUM_QUOTATION_ITEM_ROWS - existing_count, 0 ].max.times do
        quotation.quotation_items.build(tenant: current_tenant)
      end
    end
  end
end
