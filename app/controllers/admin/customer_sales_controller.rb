module Admin
  class CustomerSalesController < BaseController
    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        from: params[:from].to_s,
        to: params[:to].to_s
      }
      @period = {
        from: parse_date(params[:from]),
        to: parse_date(params[:to])
      }
      @customers = current_tenant.customers
                                 .includes(:invoices, :payments, :customer_opportunities)
                                 .search(search_keyword)
                                 .with_status(search_status)
                                 .ordered_for_admin
      @summary = {
        count: @customers.size,
        sales_total: @customers.sum { |customer| customer.sales_amount(from: @period[:from], to: @period[:to]) },
        payment_total: @customers.sum { |customer| customer.payment_amount_in_period(from: @period[:from], to: @period[:to]) },
        outstanding_total: @customers.sum(&:outstanding_invoice_amount),
        pipeline_total: @customers.sum(&:pipeline_opportunity_amount)
      }
    end

    private

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Customer.statuses.value?(status) ? status : nil
    end

    def parse_date(raw_value)
      return nil if raw_value.blank?

      Date.iso8601(raw_value)
    rescue ArgumentError
      nil
    end
  end
end
