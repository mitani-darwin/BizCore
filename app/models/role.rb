# テナント内のロール（役割）を表すモデル。
# built_in: true のロール（管理者・owner 等）は編集・削除不可。
class Role < ApplicationRecord
  belongs_to :tenant

  has_many :assignments, dependent: :destroy
  has_many :users, through: :assignments
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  scope :built_in, -> { where(built_in: true) }
  scope :custom, -> { where(built_in: false) }

  validates :name, :key, presence: true
  validates :key, uniqueness: { scope: :tenant_id }

  # 組み込みロールは UI から編集できないようにする。
  def editable?
    !built_in?
  end

  # 組み込みロールは削除できない。ユーザーがロールを失って操作不能になるのを防ぐ。
  def deletable?
    !built_in?
  end
end
