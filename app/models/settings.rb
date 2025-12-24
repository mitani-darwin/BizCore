module Settings
  DEFAULTS = {}.freeze

  def self.get(key, tenant: nil, default: nil)
    DEFAULTS.fetch(key.to_sym, default)
  end
end
