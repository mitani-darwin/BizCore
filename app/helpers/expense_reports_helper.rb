# 経費精算画面の View ヘルパー。カテゴリ・ステータスの select オプションとラベル変換を提供する。
module ExpenseReportsHelper
  EXPENSE_CATEGORY_OPTIONS = [
    [ "交通費",   "transportation" ],
    [ "接待費",   "entertainment" ],
    [ "消耗品費", "supplies" ],
    [ "通信費",   "communication" ],
    [ "その他",   "other" ]
  ].freeze

  def expense_category_options
    EXPENSE_CATEGORY_OPTIONS
  end

  def expense_category_label(category)
    EXPENSE_CATEGORY_OPTIONS.find { |_, v| v == category.to_s }&.first || category.to_s
  end
end
