# 業種別に有効なナビゲーションセクションを管理するモジュール。
# FeatureFlags.section_enabled?(section_id, tenant:) でセクション表示を制御する。
# セクション ID は Admin::Navigation の Section#id と対応している。
module FeatureFlags
  # 常に表示するセクション（業種に関わらず）
  ALWAYS_ON = %i[core system].freeze

  # 業種ごとに有効なセクション ID の一覧
  INDUSTRY_SECTIONS = {
    "general" => %i[
      workforce sales ordering inventory procurement site_management accounting
    ],
    "construction" => %i[
      workforce ordering site_management procurement accounting
    ],
    "retail" => %i[
      workforce sales ordering inventory procurement accounting
    ],
    "service" => %i[
      workforce sales ordering accounting
    ]
  }.freeze

  def self.section_enabled?(section_id, tenant: nil)
    key = section_id.to_sym
    return true if ALWAYS_ON.include?(key)

    industry = tenant&.industry.presence || "general"
    allowed  = INDUSTRY_SECTIONS.fetch(industry, INDUSTRY_SECTIONS["general"])
    allowed.include?(key)
  end
end
