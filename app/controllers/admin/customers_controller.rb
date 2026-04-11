module Admin
  class CustomersController < BaseController
    before_action :set_customer, only: [:show, :edit, :update]

    def index
      @customers = current_tenant.customers.order(:code, :id)
    end

    def show; end

    def new
      @customer = current_tenant.customers.build(
        closing_day: 31,
        invoice_delivery_method: "email",
        payment_method: "bank_transfer",
        payment_due_rule: "next_month_end"
      )
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
      @customer = current_tenant.customers.find_by(id: params[:id])
      return if @customer

      render_not_found and return false
    end

    def customer_params
      params.require(:customer).permit(
        :code,
        :name,
        :name_kana,
        :postal_code,
        :address1,
        :address2,
        :tel,
        :email,
        :closing_day,
        :payment_due_rule,
        :payment_method,
        :invoice_delivery_method,
        :note
      )
    end
  end
end
