module Admin
  class RolesController < ApplicationController
    before_action :set_tenant

    def index
      @roles = @tenant.roles.order(:name)
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
      @tenant_search_results = search_tenants(@tenant_search_name, @tenant_search_code, @tenant_search_subdomain)
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end

    def search_tenants(name, code, subdomain)
      return [] if name.blank? && code.blank? && subdomain.blank?

      scope = Tenant.all
      scope = scope.where(Tenant.arel_table[:name].matches("%#{name}%")) if name.present?
      scope = scope.where(Tenant.arel_table[:code].matches("%#{code}%")) if code.present?
      scope = scope.where(Tenant.arel_table[:subdomain].matches("%#{subdomain}%")) if subdomain.present?
      scope.order(:name).limit(10)
    end
  end
end
