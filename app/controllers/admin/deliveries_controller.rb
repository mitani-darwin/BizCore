module Admin
  class DeliveriesController < BaseController
    before_action :set_delivery, only: [ :show, :download_excel, :download_pdf ]

    def index
      @pagy, @deliveries = pagy(current_tenant.deliveries.includes(:customer, :order).order(delivery_date: :desc, id: :desc))
    end

    def show; end

    def download_excel
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "delivery")
      send_data(
        Deliveries::ExportXlsx.call(delivery: @delivery, template: template),
        filename: "#{@delivery.delivery_number}.xlsx",
        type: Reports::BaseXlsx::MIME_TYPE,
        disposition: :attachment
      )
    end

    def download_pdf
      template = DocumentTemplate.for_tenant_and_type(current_tenant, "delivery")
      send_data(
        Deliveries::ExportPdf.call(delivery: @delivery, template: template),
        filename: "#{@delivery.delivery_number}.pdf",
        type: Reports::BasePdf::MIME_TYPE,
        disposition: :attachment
      )
    end

    private

    def set_delivery
      @delivery = current_tenant.deliveries.includes(:customer, :order, delivery_items: :product).find_by(id: params[:id])
      return if @delivery

      render_not_found and return false
    end
  end
end
