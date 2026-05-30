# コントローラと View から権限チェックを行うためのヘルパーモジュール。
# ApplicationController に include され、current_user と current_tenant を暗黙的に使う。
module AuthorizationHelper
  # 権限キーを保有しているか真偽値で返す。View の条件分岐に使う。
  def can?(permission_key)
    Authorization.can?(actor: current_user, tenant: current_tenant, key: permission_key)
  end

  # 権限キーを保有していない場合は AuthorizationError を上げる。コントローラの before_action 等で使う。
  def authorize!(permission_key)
    Authorization.authorize!(actor: current_user, tenant: current_tenant, key: permission_key)
  end
end
