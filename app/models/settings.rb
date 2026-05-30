# テナント・アプリ設定を取得するモジュール。
# 現時点は DEFAULTS が空で DB 永続化もないが、将来の設定拡張用の入口として存在する。
module Settings
  DEFAULTS = {}.freeze

  # 指定キーの設定値を返す。未定義の場合は default を返す。
  def self.get(key, tenant: nil, default: nil)
    DEFAULTS.fetch(key.to_sym, default)
  end
end
