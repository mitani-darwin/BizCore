# ロールと権限の紐づけを表す中間テーブルモデル。
class RolePermission < ApplicationRecord
  belongs_to :role
  belongs_to :permission

  validates :role_id, uniqueness: { scope: :permission_id }
end
