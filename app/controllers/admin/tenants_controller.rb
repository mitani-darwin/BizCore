module Admin
  class TenantsController < ApplicationController
    def new
      @tenant = Tenant.new
    end

    def create
      @tenant = Tenant.new(tenant_params)
      if @tenant.save
        redirect_to admin_tenants_path, notice: "テナントを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def index
      @tenants = Tenant.all
      @tenants = apply_filters(@tenants)
      @tenants = apply_sort(@tenants)
    end

    private

    def apply_filters(scope)
      filtered = scope
      if params[:q].present?
        query = "%#{params[:q]}%"
        filtered = filtered.where(
          Tenant.arel_table[:name].matches(query)
            .or(Tenant.arel_table[:code].matches(query))
            .or(Tenant.arel_table[:subdomain].matches(query))
        )
      end

      filtered = filtered.where(status: params[:status]) if params[:status].present?
      filtered = filtered.where(plan: params[:plan]) if params[:plan].present?
      filtered
    end

    def apply_sort(scope)
      case params[:sort]
      when "created_desc"
        scope.order(created_at: :desc)
      when "created_asc"
        scope.order(created_at: :asc)
      when "name"
        scope.order(name: :asc)
      else
        scope.order(updated_at: :desc)
      end
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
