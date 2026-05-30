module Admin
  # 契約管理の CRUD を管理する。得意先・仕入先・その他の相手方タイプに対応する。
  # expire_alert アクションで契約期限アラートジョブを手動実行できる。
  class ContractsController < BaseController
    before_action :set_contract, only: %i[show edit update]
    before_action :set_form_options, only: %i[new create edit update]

    def index
      @alert_filter = params[:alert].presence
      @filters = {
        q:                  search_keyword,
        status:             search_status,
        counterparty_type:  search_counterparty_type,
        alert:              @alert_filter
      }

      base_query = current_tenant.contracts
                                 .includes(:customer, :supplier)
                                 .search(search_keyword)
                                 .with_status(search_status)
                                 .with_counterparty_type(search_counterparty_type)

      # アラートフィルター
      filtered_query = case @alert_filter
      when "expiring_soon" then base_query.where(status: "active").expiring_within(Contract::ALERT_THRESHOLDS.max)
      when "expired"       then base_query.already_expired
      else                      base_query
      end

      @summary = {
        count:          base_query.size,
        active_count:   base_query.count(&:status_active?),
        expiring_soon:  current_tenant.contracts.where(status: "active").expiring_within(Contract::ALERT_THRESHOLDS.max).count,
        already_expired: current_tenant.contracts.already_expired.count
      }
      @pagy, @contracts = pagy(filtered_query.ordered_for_admin)
    end

    # POST /admin/contracts/expire_alert — 管理者が手動でアラートジョブを起動する。
    def expire_alert
      authorize!("admin.contracts.read")
      ContractExpiryAlertJob.perform_later
      redirect_to admin_contracts_path, notice: "契約期限チェックをキューに追加しました。"
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
