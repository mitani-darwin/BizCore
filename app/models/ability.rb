require "set"

# 権限チェックを担うオブジェクト。User#can? から呼び出される。
# owner ロールまたは is_owner? フラグを持つユーザーはすべての権限キーに対して true を返す。
# permission_keys はリクエスト中にキャッシュされるため N+1 にならない。
class Ability
  def initialize(user)
    @user = user
  end

  # 指定の権限キーを保有しているかを返す。ユーザーが nil の場合は常に false。
  def can?(permission_key)
    return false if @user.nil?
    return true if owner_role?

    permission_keys.include?(permission_key)
  end

  private

  # is_owner? フラグまたは "owner" キーのロールを持つ場合に true を返す。
  # メモ化により同一リクエスト内で DB 問い合わせは 1 回のみ。
  def owner_role?
    @owner_role ||= @user.is_owner? || @user.roles.where(key: "owner").exists?
  end

  # ユーザーの全権限キーを Set で保持してメモ化する。
  def permission_keys
    @permission_keys ||= @user.permissions.pluck(:key).to_set
  end
end
