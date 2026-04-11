module Admin
  class DeliveriesController < BaseController
    before_action :set_delivery, only: [:show]

    def index
      @deliveries = current_tenant.deliveries.includes(:customer, :order).order(delivery_date: :desc, id: :desc)
    end

    def show; end

    private

    def set_delivery
      @delivery = current_tenant.deliveries.includes(:customer, :order, delivery_items: :product).find_by(id: params[:id])
      return if @delivery

      render_not_found and return false
    end
  end
end
