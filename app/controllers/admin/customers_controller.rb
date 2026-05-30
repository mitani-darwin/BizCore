module Admin
  # 得意先マスタの CRUD を管理する。show は売掛残高・エイジング等の財務サマリーも表示する。
  class CustomersController < BaseController
    before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

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

    def destroy
      unless @customer.deletable?
        redirect_to admin_customer_path(@customer), alert: @customer.deletion_blocked_reason and return
      end

      @customer.destroy!
      audit!(action_key: required_permission_key, metadata: { code: @customer.code, name: @customer.name })
      redirect_to admin_customers_path, notice: "得意先「#{@customer.name}」を削除しました。"
    rescue ActiveRecord::DeleteRestrictionError => e
      redirect_to admin_customer_path(@customer), alert: "削除できませんでした: #{e.message}"
    end

    # GET / POST /admin/customers/import
    def import
      return unless request.post?

      file = params[:file]
      unless file.present?
        flash.now[:alert] = "ファイルを選択してください。"
        render :import, status: :unprocessable_entity and return
      end

      csv_string = file.read.force_encoding("UTF-8")
      @import_result = Imports::CustomerImport.call(tenant: current_tenant, csv_string: csv_string)
      audit!(action_key: required_permission_key, metadata: { total: @import_result.total, succeeded: @import_result.succeeded })
    rescue ArgumentError => e
      flash.now[:alert] = e.message
    end

    # GET /admin/customers/import_template
    def import_template
      csv = Imports::CustomerImport.template_csv
      send_data(csv.encode("UTF-8"), filename: "得意先インポートテンプレート.csv", type: "text/csv; charset=UTF-8", disposition: :attachment)
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
