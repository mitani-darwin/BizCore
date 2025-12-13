module Admin
  class DashboardPolicy < ::ApplicationPolicy
    def index?
      access?
    end

    def access?
      return false unless user&.tenant_id

      owner? || user.can?("admin:access") || user.can?("admin:dashboard")
    end

    private

    def owner?
      (user.respond_to?(:is_owner?) && user.is_owner?) ||
        user.roles.where(tenant_id: user.tenant_id, key: "owner").exists?
    end
  end
end
