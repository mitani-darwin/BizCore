module Admin
  class PermissionPolicy < ::ApplicationPolicy
    def index?
      manage?
    end

    def create?
      manage?
    end

    def update?
      manage?
    end

    def destroy?
      manage?
    end

    def manage?
      return false unless user&.tenant_id

      owner? || user.can?("permissions:manage")
    end

    class Scope < ::ApplicationPolicy::Scope
      def resolve
        return scope.none unless user&.tenant_id

        scope.all
      end
    end

    private

    def owner?
      user.respond_to?(:is_owner?) && user.is_owner?
    end
  end
end
