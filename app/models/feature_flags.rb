# フィーチャーフラグを管理するモジュール。
# FLAGS が空の間は全フラグが disabled 扱いになる。テナント別の段階リリースに拡張予定。
module FeatureFlags
  FLAGS = {}.freeze

  # 指定フラグが有効かどうかを返す。未定義の場合は false。
  def self.enabled?(key, tenant: nil)
    FLAGS.fetch(key.to_sym, false)
  end
end
