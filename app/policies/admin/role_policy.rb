module Admin
  class RolePolicy < ::ApplicationPolicy
    def index?
      manage?
    end

    def update_permissions?
      manage?
    end

    def manage?
      return false unless user&.tenant_id
      return false unless tenant_match?

      owner? || user.can?("roles:manage") || user.can?("permissions:manage")
    end

    class Scope < ::ApplicationPolicy::Scope
      def resolve
        return scope.none unless user&.tenant_id

        scope.where(tenant_id: user.tenant_id)
      end
    end

    private

    def owner?
      user.respond_to?(:is_owner?) && user.is_owner?
    end

    def tenant_match?
      return true if record.is_a?(Class)

      record.respond_to?(:tenant_id) && record.tenant_id == user.tenant_id
    end
  end
end
