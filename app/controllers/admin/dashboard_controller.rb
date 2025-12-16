module Admin
  class DashboardController < BaseController
    def index
      @tenant = current_tenant
      @user_count = @tenant.users.count
      @role_count = @tenant.roles.count
    end
  end
end
