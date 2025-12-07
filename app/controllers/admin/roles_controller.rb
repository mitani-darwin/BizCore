module Admin
  class RolesController < ApplicationController
    before_action :set_tenant

    def index
      @roles = @tenant.roles.order(:name)
      @tenant_search_query = params[:tenant_search].to_s.strip
      @tenant_search_results = search_tenants(@tenant_search_query)
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end

    def search_tenants(query)
      return [] if query.blank?

      pattern = "%#{query}%"
      Tenant.where(
        Tenant.arel_table[:name].matches(pattern)
          .or(Tenant.arel_table[:code].matches(pattern))
          .or(Tenant.arel_table[:subdomain].matches(pattern))
      ).order(:name).limit(10)
    end
  end
end
