require "ostruct"

module Admin
  class ApplicationController < ::ApplicationController
    layout "admin"

    helper_method :current_admin_user, :current_tenant

    private

    def current_admin_user
      @current_admin_user ||= OpenStruct.new(email: "admin@example.com")
    end

    def current_tenant
      @current_tenant ||= Tenant.first
    end
  end
end
