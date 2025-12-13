module Admin
  class TenantsController < ApplicationController
    before_action :set_tenant, only: %i[show edit update destroy]

    def new
      authorize Tenant, :create?
      @tenant = Tenant.new
    end

    def show
      authorize @tenant, :show?
    end

    def edit
      authorize @tenant, :update?
    end

    def create
      authorize Tenant, :create?
      @tenant = Tenant.new(tenant_params)
      if @tenant.save
        redirect_to admin_tenants_path, notice: "テナントを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @tenant, :update?
      if @tenant.update(tenant_params)
        redirect_to admin_tenant_path(@tenant), notice: "テナントを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @tenant, :destroy?
      @tenant.destroy!
      redirect_to admin_tenants_path, notice: "テナントを削除しました。"
    end

    def index
      authorize Tenant, :index?

      @tenants = policy_scope(Tenant)
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

    def set_tenant
      @tenant = policy_scope(Tenant).find(params[:id])
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
