module Admin
  class StockItemsController < BaseController
    before_action :set_stock_item, only: [:edit, :update]
    before_action :set_options, only: [:new, :create, :edit, :update]

    def index
      @stock_items = current_tenant.stock_items.includes(:warehouse, :product).joins(:warehouse, :product).order("warehouses.name ASC, products.name ASC")
    end

    def new
      @stock_item = current_tenant.stock_items.build(quantity_on_hand: 0, quantity_reserved: 0)
    end

    def create
      @stock_item = current_tenant.stock_items.build(stock_item_create_params)
      @stock_item.quantity_reserved = 0

      if @stock_item.save
        redirect_to admin_stock_items_path, notice: "在庫を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @stock_item.update(stock_item_update_params)
        redirect_to admin_stock_items_path, notice: "在庫を更新しました。"
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
      params.require(:stock_item).permit(:warehouse_id, :product_id, :quantity_on_hand)
    end

    def stock_item_update_params
      params.require(:stock_item).permit(:quantity_on_hand)
    end
  end
end
