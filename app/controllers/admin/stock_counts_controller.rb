module Admin
  class StockCountsController < BaseController
    before_action :set_options, only: [ :new, :create ]

    def index
      @pagy, @stock_counts = pagy(current_tenant.stock_counts.includes(:warehouse, :product, :stock_item).recent)
    end

    def new
      @stock_count = current_tenant.stock_counts.build(counted_at: Time.current)
      @selected_stock_item = selected_stock_item
      @stock_count.stock_item = @selected_stock_item if @selected_stock_item
    end

    def create
      @selected_stock_item = selected_stock_item || find_stock_item_from_params
      raise ArgumentError, "棚卸対象の在庫を選択してください" if @selected_stock_item.nil?

      counted_at = parse_counted_at(params.dig(:stock_count, :counted_at))
      stock_count = Inventory::CountStock.call(
        stock_item: @selected_stock_item,
        counted_quantity: params.dig(:stock_count, :counted_quantity),
        counted_at: counted_at,
        note: params.dig(:stock_count, :note)
      )

      redirect_to admin_stock_item_path(stock_count.stock_item), notice: "棚卸結果を登録しました。"
    rescue StandardError => e
      @stock_count = current_tenant.stock_counts.build(stock_count_form_params)
      @stock_count.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end

    private

    def set_options
      @stock_item_options = current_tenant.stock_items.includes(:warehouse, :product).joins(:warehouse, :product).order("warehouses.name ASC, products.name ASC")
    end

    def selected_stock_item
      stock_item_id = params[:stock_item_id].presence || params.dig(:stock_count, :stock_item_id).presence
      return if stock_item_id.blank?

      current_tenant.stock_items.find_by(id: stock_item_id)
    end

    def find_stock_item_from_params
      current_tenant.stock_items.find_by(id: params.dig(:stock_count, :stock_item_id))
    end

    def stock_count_form_params
      params.fetch(:stock_count, {}).permit(:stock_item_id, :counted_quantity, :counted_at, :note)
    end

    def parse_counted_at(value)
      return Time.current if value.blank?

      Time.zone.parse(value)
    rescue ArgumentError, TypeError
      raise ArgumentError, "棚卸日時の形式が正しくありません"
    end
  end
end
