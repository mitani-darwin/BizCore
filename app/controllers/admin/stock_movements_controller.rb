module Admin
  # 在庫移動履歴の閲覧と手動在庫調整の登録を管理する。
  # create で Inventory::AdjustStock サービスを呼んで StockItem と StockMovement を同時に更新する。
  class StockMovementsController < BaseController
    before_action :set_movement, only: [ :show ]
    before_action :set_options, only: [ :new, :create ]

    def index
      @pagy, @stock_movements = pagy(current_tenant.stock_movements.includes(:warehouse, :product).recent)
    end

    def show; end

    def new
      @movement = current_tenant.stock_movements.build(
        occurred_on: Date.current,
        movement_type: "inbound"
      )
      @selected_stock_item = selected_stock_item
      if @selected_stock_item
        @movement.warehouse = @selected_stock_item.warehouse
        @movement.product = @selected_stock_item.product
      end
    end

    def create
      @movement = current_tenant.stock_movements.build(movement_params)
      stock_item = find_or_prepare_stock_item!

      recorded = Inventory::RecordMovement.call(
        stock_item: stock_item,
        movement_type: @movement.movement_type,
        quantity: @movement.quantity,
        occurred_on: @movement.occurred_on,
        note: @movement.note
      )

      redirect_to admin_stock_movement_path(recorded), notice: "在庫移動を登録しました。"
    rescue StandardError => e
      @selected_stock_item = selected_stock_item
      @movement.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end

    private

    def set_movement
      @movement = current_tenant.stock_movements.includes(:warehouse, :product).find_by(id: params[:id])
      return if @movement

      render_not_found and return false
    end

    def set_options
      @warehouse_options = current_tenant.warehouses.order(:name)
      @product_options = current_tenant.products.order(:name)
      @stock_item_options = current_tenant.stock_items.includes(:warehouse, :product).joins(:warehouse, :product).order("warehouses.name ASC, products.name ASC")
    end

    def movement_params
      params.require(:stock_movement).permit(:warehouse_id, :product_id, :movement_type, :quantity, :occurred_on, :note)
    end

    def selected_stock_item
      stock_item_id = params[:stock_item_id].presence || params.dig(:stock_movement, :stock_item_id).presence
      return if stock_item_id.blank?

      current_tenant.stock_items.find_by(id: stock_item_id)
    end

    def find_or_prepare_stock_item!
      movement = movement_params
      warehouse_id = selected_stock_item&.warehouse_id || movement[:warehouse_id]
      product_id = selected_stock_item&.product_id || movement[:product_id]

      raise ArgumentError, "倉庫を選択してください" if warehouse_id.blank?
      raise ArgumentError, "商品を選択してください" if product_id.blank?

      stock_item = current_tenant.stock_items.find_or_initialize_by(
        warehouse_id: warehouse_id,
        product_id: product_id
      )
      return stock_item if stock_item.persisted?

      if movement[:movement_type] == "adjustment_decrease"
        raise ArgumentError, "減算調整する在庫が存在しません"
      end

      stock_item.quantity_on_hand = 0
      stock_item.quantity_reserved = 0
      stock_item.safety_stock = 0
      stock_item.save!
      stock_item
    end
  end
end
