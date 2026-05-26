module Admin
  class SuppliersController < BaseController
    before_action :set_supplier, only: [ :show, :edit, :update ]

    def index
      @filters = { q: search_keyword, status: search_status }
      query = current_tenant.suppliers
                            .search(search_keyword)
                            .with_status(search_status)
                            .ordered_for_admin
      @summary = {
        count: query.size,
        active_count: query.count(&:active?)
      }
      @pagy, @suppliers = pagy(query)
    end

    def show
      @recent_purchase_orders = @supplier.purchase_orders.order(order_date: :desc, id: :desc).limit(5)
      @recent_purchase_receipts = @supplier.purchase_receipts.order(received_on: :desc, id: :desc).limit(5)
    end

    def new
      @supplier = current_tenant.suppliers.build(
        status: "active",
        payment_method: "bank_transfer",
        payment_due_rule: "next_month_end",
        closing_day: 31
      )
    end

    def create
      @supplier = current_tenant.suppliers.build(supplier_params)

      if @supplier.save
        redirect_to admin_supplier_path(@supplier), notice: "仕入先を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @supplier.update(supplier_params)
        redirect_to admin_supplier_path(@supplier), notice: "仕入先を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_supplier
      @supplier = current_tenant.suppliers.find_by(id: params[:id])
      return if @supplier

      render_not_found and return false
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      status = params[:status].to_s
      Supplier.statuses.value?(status) ? status : nil
    end

    def supplier_params
      params.require(:supplier).permit(
        :code,
        :name,
        :name_kana,
        :status,
        :postal_code,
        :address1,
        :address2,
        :tel,
        :email,
        :contact_person_department,
        :contact_person_name,
        :contact_person_email,
        :contact_person_tel,
        :closing_day,
        :payment_due_rule,
        :payment_method,
        :note
      )
    end
  end
end
