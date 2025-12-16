require "set"

class Ability
  def initialize(user)
    @user = user
  end

  def can?(permission_key)
    return false if @user.nil?
    return true if owner_role?

    permission_keys.include?(permission_key)
  end

  private

  def owner_role?
    @owner_role ||= @user.is_owner? || @user.roles.where(key: "owner").exists?
  end

  def permission_keys
    @permission_keys ||= @user.permissions.pluck(:key).to_set
  end
end
