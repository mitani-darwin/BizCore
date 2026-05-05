module Admin
  class WarehousesController < BaseController
    before_action :set_warehouse, only: [ :show, :edit, :update ]

    def index
      @warehouses = current_tenant.warehouses.order(:code, :id)
    end

    def show; end

    def new
      @warehouse = current_tenant.warehouses.build(active: true)
    end

    def create
      @warehouse = current_tenant.warehouses.build(warehouse_params)

      if @warehouse.save
        redirect_to admin_warehouse_path(@warehouse), notice: "倉庫を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @warehouse.update(warehouse_params)
        redirect_to admin_warehouse_path(@warehouse), notice: "倉庫を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_warehouse
      @warehouse = current_tenant.warehouses.find_by(id: params[:id])
      return if @warehouse

      render_not_found and return false
    end

    def warehouse_params
      params.require(:warehouse).permit(:code, :name, :active)
    end
  end
end
