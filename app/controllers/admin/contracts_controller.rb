module Admin
  # 契約管理の CRUD を管理する。得意先・仕入先・その他の相手方タイプに対応する。
  class ContractsController < BaseController
    before_action :set_contract, only: %i[show edit update]
    before_action :set_form_options, only: %i[new create edit update]

    def index
      @filters = {
        q:                  search_keyword,
        status:             search_status,
        counterparty_type:  search_counterparty_type
      }
      query = current_tenant.contracts
                            .includes(:customer, :supplier)
                            .search(search_keyword)
                            .with_status(search_status)
                            .with_counterparty_type(search_counterparty_type)
                            .ordered_for_admin
      @summary = {
        count:         query.size,
        active_count:  query.count(&:status_active?),
        expiring_soon: current_tenant.contracts.expiring_within(30).count
      }
      @pagy, @contracts = pagy(query)
    end

    def show; end

    def new
      @contract = current_tenant.contracts.build(
        started_on:        Date.current,
        counterparty_type: params[:counterparty_type] || "customer",
        customer_id:       params[:customer_id],
        supplier_id:       params[:supplier_id]
      )
    end

    def create
      @contract = current_tenant.contracts.build(contract_params)

      if @contract.save
        redirect_to admin_contract_path(@contract), notice: "契約を作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @contract.update(contract_params)
        redirect_to admin_contract_path(@contract), notice: "契約を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_contract
      @contract = current_tenant.contracts.includes(:customer, :supplier).find_by(id: params[:id])
      return if @contract

      render_not_found and return false
    end

    def set_form_options
      @customer_options = current_tenant.customers.active.ordered_for_admin
      @supplier_options = current_tenant.suppliers.active.ordered_for_admin
    end

    def search_keyword
      params[:q].to_s.strip
    end

    def search_status
      s = params[:status].to_s
      Contract.statuses.value?(s) ? s : nil
    end

    def search_counterparty_type
      t = params[:counterparty_type].to_s
      Contract.counterparty_types.value?(t) ? t : nil
    end

    def contract_params
      params.require(:contract).permit(
        :contract_number,
        :title,
        :counterparty_type,
        :customer_id,
        :supplier_id,
        :status,
        :started_on,
        :ended_on,
        :auto_renewal,
        :amount,
        :description,
        :note
      )
    end
  end
end
