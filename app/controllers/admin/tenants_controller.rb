module Admin
  class TenantsController < BaseController
    before_action :set_tenant, only: %i[show edit update]

    def index
      @tenant = current_tenant
      @tenants = [@tenant].compact
    end

    def show; end

    def edit; end

    def update
      authorize!("admin.tenants.update")
      if @tenant.update(tenant_params)
        audit!(
          action_key: "admin.tenants.update",
          auditable: @tenant,
          metadata: { changes: @tenant.saved_changes }
        )
        redirect_to admin_tenant_path(@tenant), notice: "テナントを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_tenant
      @tenant = current_tenant
      return if @tenant && params[:id].to_s == @tenant.id.to_s

      render_not_found and return false
    end

    def tenant_params
      params.require(:tenant).permit(
        :name,
        :code,
        :subdomain,
        :plan,
        :status,
        :billing_email
      )
    end
  end
end
