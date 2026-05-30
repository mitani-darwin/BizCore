# 帳票番号を自動採番する Concern。
# generates_document_number を呼ぶと before_validation (on: :create) で採番される。
# 形式: "PREFIX-YYYYMMDDHHMMSS-XXXX" (末尾4桁はランダム16進数)
module DocumentNumbering
  extend ActiveSupport::Concern

  class_methods do
    # 指定の属性が空の場合に一意な帳票番号を生成して設定する。
    # ループで重複チェックするため、衝突時は再生成する。
    def generates_document_number(attribute, prefix:)
      before_validation(on: :create) do
        next if public_send(attribute).present?

        loop do
          candidate = "#{prefix}-#{Time.current.strftime('%Y%m%d%H%M%S')}-#{SecureRandom.hex(2).upcase}"
          next if self.class.unscoped.exists?(attribute => candidate)

          self.public_send("#{attribute}=", candidate)
          break
        end
      end
    end
  end
end
