module FeatureFlags
  FLAGS = {}.freeze

  def self.enabled?(key, tenant: nil)
    FLAGS.fetch(key.to_sym, false)
  end
end
