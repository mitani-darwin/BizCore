class UserPolicy < ApplicationPolicy
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
    return false unless tenant_match?

    owner? || user.can?("users:manage")
  end

  class Scope < Scope
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
    return record.tenant_id == user.tenant_id if record.respond_to?(:tenant_id)

    true
  end
end
