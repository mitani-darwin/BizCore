class AuthorizationError < StandardError
  attr_reader :key, :reason

  def initialize(key, reason: nil)
    @key = key
    @reason = reason
    message = "Not authorized for permission key: #{key}"
    message += " (#{reason})" if reason
    super(message)
  end

  def audit_status
    "denied"
  end
end
