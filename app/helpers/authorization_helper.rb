module AuthorizationHelper
  def can?(permission_key)
    current_ability.can?(permission_key)
  end
end
