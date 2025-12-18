module AuthorizationHelper
  def can?(permission_key)
    Authorization.can?(actor: current_user, tenant: current_tenant, key: permission_key)
  end

  def authorize!(permission_key)
    Authorization.authorize!(actor: current_user, tenant: current_tenant, key: permission_key)
  end
end
