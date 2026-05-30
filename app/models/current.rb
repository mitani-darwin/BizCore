# リクエストスコープの現在ユーザーとテナントを保持するスレッドローカル属性。
# ApplicationController でリクエストごとにセットし、モデル・サービスから参照する。
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :tenant
end
