class Authorization
  def self.can?(actor:, tenant:, key:)
    return false if actor.nil? || tenant.nil?

    permission = Permission.find_by(key: key)
    return false unless permission

    return true if actor.respond_to?(:is_owner?) && actor.is_owner?

    permissions = permissions_for(actor, tenant)
    permissions&.any? { |p| p.id == permission.id } || false
  end

  def self.authorize!(actor:, tenant:, key:)
    return true if can?(actor: actor, tenant: tenant, key: key)

    reason = Permission.exists?(key: key) ? :forbidden : :unknown_permission
    raise AuthorizationError.new(key, reason: reason)
  end

  def self.permissions_for(actor, tenant)
    return [] unless actor.respond_to?(:permissions_for)

    actor.permissions_for(tenant) || []
  end
  private_class_method :permissions_for
end
