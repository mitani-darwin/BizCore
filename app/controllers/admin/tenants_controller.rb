module Admin
  class TenantsController < ApplicationController
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
  end
end
