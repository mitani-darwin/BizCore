# 日本語フォントのパスを解決するモジュール。
# 環境変数 PRAWN_JAPANESE_FONT_PATH を優先し、見つからない場合は既知のパスを順に探す。
module Reports
  module PdfFont
    SEARCH_PATHS = [
      ENV["PRAWN_JAPANESE_FONT_PATH"],
      "/Library/Fonts/Arial Unicode.ttf",
      "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      "/usr/share/fonts/truetype/ipafont-gothic/ipag.ttf",
      "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf",
      "/usr/share/fonts/ipafont-gothic/ipag.ttf",
      "/usr/share/fonts/ipa/ipag.ttf"
    ].compact.freeze

    # フォントファイルのパスを返す。見つからない場合は RuntimeError を発生させる。
    def self.font_path
      @font_path ||= SEARCH_PATHS.find { |p| p && File.exist?(p) } ||
        raise("日本語フォントが見つかりません。PRAWN_JAPANESE_FONT_PATH 環境変数でフォントパスを指定してください。")
    end
  end
end
