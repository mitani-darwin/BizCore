module Admin
  class RolesController < ApplicationController
    before_action :set_tenant

    def index
      @roles = @tenant.roles.order(:name)
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end
  end
end
