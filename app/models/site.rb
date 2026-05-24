# 現場・案件を管理するモデル
class Site < ApplicationRecord
  CATEGORIES = {
    construction: "construction",  # 建設工事
    maintenance: "maintenance",    # 保守・メンテナンス
    other: "other"                 # その他
  }.freeze

  STATUSES = {
    planning: "planning",       # 計画中
    active: "active",           # 施工中
    on_hold: "on_hold",         # 一時停止
    completed: "completed",     # 完了
    cancelled: "cancelled"      # キャンセル
  }.freeze

  CATEGORY_LABELS = {
    "construction" => "建設工事",
    "maintenance" => "保守・メンテナンス",
    "other" => "その他"
  }.freeze

  STATUS_LABELS = {
    "planning" => "計画中",
    "active" => "施工中",
    "on_hold" => "一時停止",
    "completed" => "完了",
    "cancelled" => "キャンセル"
  }.freeze

  belongs_to :tenant
  has_many :daily_reports, dependent: :destroy

  enum :status, STATUSES
  enum :category, CATEGORIES

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :tenant_id, message: "はこのテナント内ですでに使われています" }
  validates :category, presence: true
  validates :status, presence: true
  validates :progress_percentage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :ordered_for_admin, -> { order(created_at: :desc, id: :desc) }

  # カテゴリの表示ラベルを返す
  def category_label
    CATEGORY_LABELS.fetch(category.to_s, category.to_s)
  end

  # ステータスの表示ラベルを返す
  def status_label
    STATUS_LABELS.fetch(status.to_s, status.to_s)
  end
end
