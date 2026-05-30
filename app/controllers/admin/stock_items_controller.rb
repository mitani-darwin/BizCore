module Admin
  # 倉庫ごとの在庫の閲覧・調整を管理する。
  # update で adjust_on_hand! を呼ぶことで在庫数を調整できる。
  class StockItemsController < BaseController
    before_action :set_stock_item, only: [ :show, :edit, :update ]
    before_action :set_options, only: [ :new, :create, :edit, :update ]

    def index
      base = current_tenant.stock_items.includes(:warehouse, :product).ordered_for_admin

      # アラート件数（バッジ表示用。タブ切替に関わらず常に算出する）
      @low_stock_count  = current_tenant.stock_items.low_stock.count
      @out_of_stock_count = current_tenant.stock_items.out_of_stock.count

      @alert_filter = params[:alert].presence

      query = case @alert_filter
              when "low_stock"    then base.low_stock
              when "out_of_stock" then base.out_of_stock
              else                     base
              end

      @pagy, @stock_items = pagy(query)
    end

    def show
      @recent_movements = current_tenant.stock_movements.where(warehouse_id: @stock_item.warehouse_id, product_id: @stock_item.product_id).recent.limit(20)
      @recent_counts = @stock_item.stock_counts.recent.limit(10)
    end

    def new
      @stock_item = current_tenant.stock_items.build(quantity_on_hand: 0, quantity_reserved: 0, safety_stock: 0)
    end

    def create
      initial_quantity = stock_item_create_params[:quantity_on_hand].to_i
      @stock_item = current_tenant.stock_items.build(
        stock_item_create_params.except(:quantity_on_hand)
      )
      @stock_item.quantity_on_hand = 0
      @stock_item.quantity_reserved = 0

      if @stock_item.save
        if initial_quantity.positive?
          Inventory::RecordMovement.call(
            stock_item: @stock_item,
            movement_type: "inbound",
            quantity: initial_quantity,
            occurred_on: Date.current,
            note: "初期在庫登録"
          )
        end

        redirect_to admin_stock_item_path(@stock_item), notice: "在庫を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    rescue StandardError => e
      @stock_item.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end

    def edit; end

    def update
      if @stock_item.update(stock_item_update_params)
        redirect_to admin_stock_item_path(@stock_item), notice: "在庫設定を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_stock_item
      @stock_item = current_tenant.stock_items.includes(:warehouse, :product).find_by(id: params[:id])
      return if @stock_item

      render_not_found and return false
    end

    def set_options
      @warehouse_options = current_tenant.warehouses.order(:name)
      @product_options = current_tenant.products.order(:name)
    end

    def stock_item_create_params
      params.require(:stock_item).permit(:warehouse_id, :product_id, :quantity_on_hand, :safety_stock)
    end

    def stock_item_update_params
      params.require(:stock_item).permit(:safety_stock)
    end
  end
end
