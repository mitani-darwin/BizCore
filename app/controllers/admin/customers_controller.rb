module Admin
  class CustomersController < BaseController
    before_action :set_customer, only: [ :show, :edit, :update ]

    def index
      @filters = { q: search_keyword, status: search_status }
      query = current_tenant.customers
                            .includes(:orders, :invoices)
                            .search(search_keyword)
                            .with_status(search_status)
                            .ordered_for_admin
      @customer_summary = {
        count: query.size,
        active_count: query.count(&:active?),
        unpaid_invoice_count: query.sum(&:unpaid_invoice_count),
        outstanding_amount: query.sum(&:outstanding_invoice_amount)
      }
      @pagy, @customers = pagy(query)
    end

    def show
      @recent_customer_inquiries = @customer.customer_inquiries.order(inquiry_date: :desc, id: :desc).limit(5)
      @recent_customer_opportunities = @customer.customer_opportunities.order(opened_on: :desc, id: :desc).limit(5)
      @recent_orders = @customer.orders.order(order_date: :desc, id: :desc).limit(5)
      @recent_invoices = @customer.invoices.order(invoice_date: :desc, id: :desc).limit(5)
      @recent_payments = @customer.payments.order(payment_date: :desc, id: :desc).limit(5)
    end

    def new
      @customer = current_tenant.customers.build(default_customer_attributes.merge(prefilled_customer_attributes))
    end

    def create
      @customer = current_tenant.customers.build(customer_params)

      if @customer.save
        redirect_to admin_customer_path(@customer), notice: "得意先を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @customer.update(customer_params)
        redirect_to admin_customer_path(@customer), notice: "得意先を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = current_tenant.customers.includes(:orders, :invoices, :payments, :customer_inquiries, :customer_opportunities).find_by(id: params[:id])
      return if @customer

      render_not_found and return false
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Customer.statuses.value?(status) ? status : nil
    end

    def customer_params
      params.require(:customer).permit(
        :code,
        :name,
        :name_kana,
        :status,
        :postal_code,
        :address1,
        :address2,
        :tel,
        :email,
        :contact_person_name,
        :contact_person_department,
        :contact_person_email,
        :contact_person_tel,
        :closing_day,
        :payment_due_rule,
        :payment_method,
        :invoice_delivery_method,
        :note
      )
    end

    def default_customer_attributes
      {
        closing_day: 31,
        status: "active",
        invoice_delivery_method: "email",
        payment_method: "bank_transfer",
        payment_due_rule: "next_month_end"
      }
    end

    def prefilled_customer_attributes
      params.fetch(:customer, {}).permit(
        :name,
        :email,
        :tel,
        :contact_person_name,
        :contact_person_department,
        :contact_person_email,
        :contact_person_tel,
        :note
      )
    end
  end
end
