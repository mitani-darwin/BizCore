# 従業員が現場ごとに提出する日報モデル
class DailyReport < ApplicationRecord
  belongs_to :tenant
  belongs_to :site
  belongs_to :employee

  has_many_attached :photos

  validates :report_date, presence: true
  validates :work_content, presence: true
  validates :work_hours, numericality: { greater_than: 0 }

  scope :ordered_for_admin, -> { order(report_date: :desc, id: :desc) }
end
