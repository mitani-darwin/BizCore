module Admin
  # 権限割当画面への操作権限を定義する Pundit ポリシー。
  class AuthorizationPolicy < ::ApplicationPolicy
    def show?
      manage?
    end

    def update?
      manage?
    end

    def manage?
      return false unless user&.tenant_id

      owner? || user.can?("permissions:manage") || user.can?("roles:manage")
    end

    private

    def owner?
      user.respond_to?(:is_owner?) && user.is_owner?
    end
  end
end
