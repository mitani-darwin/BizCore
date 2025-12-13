class TenantPolicy < ApplicationPolicy
  def index?
    manage?
  end

  def show?
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

  class Scope < Scope
    def resolve
      return scope.none unless user&.tenant_id

      scope.where(id: user.tenant_id)
    end
  end

  private

  def manage?
    return false unless user&.tenant_id
    return false unless tenant_match?

    owner? || user.can?("tenants:manage")
  end

  def owner?
    user.respond_to?(:is_owner?) && user.is_owner?
  end

  def tenant_match?
    return true if record.is_a?(Class)
    return record.id == user.tenant_id if record.is_a?(Tenant)

    record.respond_to?(:tenant_id) ? record.tenant_id == user.tenant_id : true
  end
end
