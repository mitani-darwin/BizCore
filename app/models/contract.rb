# 契約書を表すモデル。得意先・仕入先・その他の相手方タイプを持つ。
# counterparty_type によって customer_id / supplier_id のどちらかのみ有効になる。
class Contract < ApplicationRecord
  COUNTERPARTY_TYPES = {
    customer: "customer",
    supplier: "supplier",
    other:    "other"
  }.freeze

  STATUSES = {
    draft:     "draft",
    active:    "active",
    expired:   "expired",
    cancelled: "cancelled"
  }.freeze

  belongs_to :tenant
  belongs_to :customer, optional: true
  belongs_to :supplier, optional: true

  enum :counterparty_type, COUNTERPARTY_TYPES, prefix: true
  enum :status,            STATUSES,           prefix: true

  scope :search, lambda { |keyword|
    next all if keyword.blank?

    pattern = "%#{sanitize_sql_like(keyword.strip)}%"
    where("contract_number LIKE :p OR title LIKE :p", p: pattern)
  }
  # アラート通知の閾値（日数）。この日数以内に期限を迎える有効な契約が通知対象になる。
  ALERT_THRESHOLDS = [ 30, 14, 7, 3 ].freeze

  scope :with_status,            ->(s)    { s.present? ? where(status: s) : all }
  scope :with_counterparty_type, ->(t)   { t.present? ? where(counterparty_type: t) : all }
  scope :expiring_within,        ->(days) { where(ended_on: Date.current..days.days.from_now.to_date) }
  scope :already_expired,        -> { where(status: "active").where("ended_on < ?", Date.current) }
  scope :ordered_for_admin, -> { order(started_on: :desc, id: :desc) }

  validates :contract_number, :title, :counterparty_type, :status, :started_on, presence: true
  validates :contract_number, uniqueness: { scope: :tenant_id }
  validate  :counterparty_presence
  validate  :end_date_after_start_date

  before_validation :set_defaults
  before_validation :clear_unused_counterparty

  def counterparty_name
    return customer.name if customer.present?
    return supplier.name if supplier.present?

    "-"
  end

  # 満了まで残り何日かを返す。満了日未設定の場合は nil。マイナスは既に期限切れを意味する。
  def days_until_expiry
    return nil if ended_on.blank?

    (ended_on - Date.current).to_i
  end

  # 満了日が過去の場合に true を返す。enum の "expired" ステータスとは独立して判定する。
  def expired?
    ended_on.present? && ended_on < Date.current
  end

  # 残り日数がアラート閾値のいずれかに該当するか返す。
  # 日次バッチで「今日が閾値の境界日」かどうかを判定するために使う。
  def alert_threshold_reached?
    days = days_until_expiry
    return false if days.nil?

    ALERT_THRESHOLDS.any? { |threshold| days <= threshold }
  end

  # ステータスが active で満了日が過去の場合に expired へ更新する。
  # ContractExpiryAlertJob の日次実行時に自動遷移させる。
  def auto_expire!
    return unless status_active? && expired?

    update!(status: "expired")
  end

  def title
    self[:title]
  end

  private

  def set_defaults
    self.status           ||= "draft"
    self.counterparty_type ||= "other"
  end

  def clear_unused_counterparty
    self.customer_id = nil unless counterparty_type_customer?
    self.supplier_id = nil unless counterparty_type_supplier?
  end

  def counterparty_presence
    case counterparty_type
    when "customer"
      errors.add(:customer, "を選択してください") if customer_id.blank?
    when "supplier"
      errors.add(:supplier, "を選択してください") if supplier_id.blank?
    end
  end

  def end_date_after_start_date
    return if started_on.blank? || ended_on.blank?

    errors.add(:ended_on, "は契約開始日以降である必要があります") if ended_on < started_on
  end
end
