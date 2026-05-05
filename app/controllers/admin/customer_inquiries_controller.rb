module Admin
  class CustomerInquiriesController < BaseController
    before_action :set_customer_inquiry, only: [ :show, :edit, :update ]
    before_action :set_form_options, only: [ :new, :create, :edit, :update ]

    def index
      @filters = {
        q: search_keyword,
        status: search_status,
        source: search_source,
        customer_id: search_customer_id
      }
      @customer_filter_options = current_tenant.customers.ordered_for_admin
      @customer_inquiries = current_tenant.customer_inquiries
                                         .includes(:customer, :assigned_user, :customer_opportunities)
                                         .search(search_keyword)
                                         .with_status(search_status)
                                         .with_source(search_source)
                                         .with_customer(search_customer_id)
                                         .ordered_for_admin
      @summary = {
        count: @customer_inquiries.size,
        open_count: @customer_inquiries.count(&:open?),
        unlinked_count: @customer_inquiries.count { |inquiry| inquiry.customer.blank? },
        opportunity_count: @customer_inquiries.sum { |inquiry| inquiry.customer_opportunities.size }
      }
    end

    def show
      @opportunities = @customer_inquiry.customer_opportunities.order(opened_on: :desc, id: :desc).limit(5)
    end

    def new
      @customer_inquiry = current_tenant.customer_inquiries.build(
        {
          inquiry_date: Date.current,
          response_due_date: Date.current + 3,
          status: "new",
          source: "email"
        }.merge(prefilled_attributes)
      )
    end

    def create
      @customer_inquiry = current_tenant.customer_inquiries.build(customer_inquiry_params)

      if @customer_inquiry.save
        redirect_to admin_customer_inquiry_path(@customer_inquiry), notice: "問い合わせを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @customer_inquiry.update(customer_inquiry_params)
        redirect_to admin_customer_inquiry_path(@customer_inquiry), notice: "問い合わせを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_customer_inquiry
      @customer_inquiry = current_tenant.customer_inquiries.includes(:customer, :assigned_user, customer_opportunities: :customer).find_by(id: params[:id])
      return if @customer_inquiry

      render_not_found and return false
    end

    def set_form_options
      @customer_options = current_tenant.customers.ordered_for_admin
      @user_options = current_tenant.users.order(:name)
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      CustomerInquiry.statuses.value?(status) ? status : nil
    end

    def search_source
      source = params[:source].to_s
      CustomerInquiry.sources.value?(source) ? source : nil
    end

    def search_customer_id
      customer = current_tenant.customers.find_by(id: params[:customer_id])
      customer&.id
    end

    def prefilled_attributes
      attributes = params.fetch(:customer_inquiry, {}).permit(
        :customer_id,
        :company_name,
        :contact_person_name,
        :contact_person_department,
        :contact_email,
        :contact_tel,
        :subject,
        :details
      ).to_h
      attributes["customer_id"] ||= params[:customer_id].presence
      attributes.compact_blank
    end

    def customer_inquiry_params
      params.require(:customer_inquiry).permit(
        :customer_id,
        :assigned_user_id,
        :inquiry_date,
        :response_due_date,
        :status,
        :source,
        :company_name,
        :contact_person_name,
        :contact_person_department,
        :contact_email,
        :contact_tel,
        :subject,
        :details
      )
    end
  end
end
