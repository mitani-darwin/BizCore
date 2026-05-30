module Admin
  # 得意先別の売上集計レポートを表示する読み取り専用コントローラ。
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
      query = current_tenant.customers
                            .includes(:invoices, :payments, :customer_opportunities)
                            .search(search_keyword)
                            .with_status(search_status)
                            .ordered_for_admin
      @summary = {
        count: query.size,
        sales_total: query.sum { |customer| customer.sales_amount(from: @period[:from], to: @period[:to]) },
        payment_total: query.sum { |customer| customer.payment_amount_in_period(from: @period[:from], to: @period[:to]) },
        outstanding_total: query.sum(&:outstanding_invoice_amount),
        pipeline_total: query.sum(&:pipeline_opportunity_amount)
      }
      @pagy, @customers = pagy(query)
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
