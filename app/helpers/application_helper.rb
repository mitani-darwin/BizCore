# 全 View から利用できるグローバルヘルパー。
module ApplicationHelper
  def minutes_to_hm(minutes)
    total = minutes.to_i
    h = total / 60
    m = total % 60
    "#{h}時間#{m}分"
  end
end
