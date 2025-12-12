module Admin
  class UsersController < ApplicationController
    def index
      @tenant_search_name = params[:tenant_name].to_s.strip
      @tenant_search_code = params[:tenant_code].to_s.strip
      @tenant_search_subdomain = params[:tenant_subdomain].to_s.strip
      @tenant_options = Tenant.order(:name).limit(100)
      @users = User.includes(:tenant, :roles).order(updated_at: :desc)
      @users = filter_by_tenant(@users)
    end

    private

    def filter_by_tenant(scope)
      return scope if @tenant_search_name.blank? && @tenant_search_code.blank? && @tenant_search_subdomain.blank?

      tenant_table = Tenant.arel_table
      scoped = scope.joins(:tenant)
      scoped = scoped.where(tenant_table[:name].eq(@tenant_search_name)) if @tenant_search_name.present?
      scoped = scoped.where(tenant_table[:code].eq(@tenant_search_code)) if @tenant_search_code.present?
      scoped = scoped.where(tenant_table[:subdomain].eq(@tenant_search_subdomain)) if @tenant_search_subdomain.present?
      scoped
    end
  end
end
