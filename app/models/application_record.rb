# 全モデルの基底クラス。直接インスタンス化せず継承専用とする。
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
