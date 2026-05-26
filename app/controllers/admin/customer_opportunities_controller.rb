module Admin
  class CustomerOpportunitiesController < BaseController
    before_action :set_customer_opportunity, only: [ :show, :edit, :update ]
    before_action :set_form_options, only: [ :new, :create, :edit, :update ]

    def index
      @filters = {
        q: search_keyword,
        stage: search_stage,
        customer_id: search_customer_id
      }
      @customer_filter_options = current_tenant.customers.ordered_for_admin
      query = current_tenant.customer_opportunities
                            .includes(:customer, :customer_inquiry, :assigned_user)
                            .search(search_keyword)
                            .with_stage(search_stage)
                            .with_customer(search_customer_id)
                            .ordered_for_admin
      @summary = {
        count: query.size,
        open_count: query.count(&:open?),
        pipeline_amount: query.select(&:open?).sum { |opportunity| opportunity.expected_amount.to_d },
        won_amount: query.select(&:won?).sum { |opportunity| opportunity.actual_sales_amount.to_d }
      }
      @pagy, @customer_opportunities = pagy(query)
    end

    def show; end

    def new
      @customer_opportunity = current_tenant.customer_opportunities.build(
        {
          opened_on: Date.current,
          stage: "hearing",
          probability: 30
        }.merge(prefilled_attributes)
      )
    end

    def create
      @customer_opportunity = current_tenant.customer_opportunities.build(customer_opportunity_params)

      if @customer_opportunity.save
        redirect_to admin_customer_opportunity_path(@customer_opportunity), notice: "商談を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @customer_opportunity.update(customer_opportunity_params)
        redirect_to admin_customer_opportunity_path(@customer_opportunity), notice: "商談を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_customer_opportunity
      @customer_opportunity = current_tenant.customer_opportunities.includes(:customer, :customer_inquiry, :assigned_user).find_by(id: params[:id])
      return if @customer_opportunity

      render_not_found and return false
    end

    def set_form_options
      @customer_options = current_tenant.customers.ordered_for_admin
      @user_options = current_tenant.users.order(:name)
      @inquiry_options = current_tenant.customer_inquiries.ordered_for_admin.limit(100)
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_stage
      stage = params[:stage].to_s
      CustomerOpportunity.stages.value?(stage) ? stage : nil
    end

    def search_customer_id
      customer = current_tenant.customers.find_by(id: params[:customer_id])
      customer&.id
    end

    def prefilled_attributes
      attributes = params.fetch(:customer_opportunity, {}).permit(
        :customer_id,
        :customer_inquiry_id,
        :subject,
        :summary
      ).to_h

      inquiry = selected_inquiry
      if inquiry
        attributes["customer_inquiry_id"] ||= inquiry.id
        attributes["customer_id"] ||= inquiry.customer_id
        attributes["subject"] ||= inquiry.subject
        attributes["summary"] ||= inquiry.details
        attributes["assigned_user_id"] ||= inquiry.assigned_user_id
      end

      attributes["customer_id"] ||= params[:customer_id].presence
      attributes.compact_blank
    end

    def selected_inquiry
      inquiry_id = params[:inquiry_id].presence || params.dig(:customer_opportunity, :customer_inquiry_id).presence
      return if inquiry_id.blank?

      current_tenant.customer_inquiries.find_by(id: inquiry_id)
    end

    def customer_opportunity_params
      params.require(:customer_opportunity).permit(
        :customer_id,
        :customer_inquiry_id,
        :assigned_user_id,
        :opened_on,
        :expected_close_on,
        :closed_on,
        :stage,
        :subject,
        :expected_amount,
        :actual_sales_amount,
        :probability,
        :summary,
        :next_action
      )
    end
  end
end
