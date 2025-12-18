あなたは Rails 8 / 業務システム向けマルチテナントSaaS の管理画面設計に精通したエンジニアです。
Step3 で実装した can?(key) / authorize!(key) を利用して、管理画面サイドバーの表示を
**「見えるメニュー＝できること」**に 完全一致させる仕組みを実装してください。

⸻

前提（既に存在するもの）
	•	Permission（Step2: admin.* seed 済み）
	•	Authorization.can? と Controller/View で使える can?(key)（Step3）
	•	管理画面レイアウトに admin/shared/_sidebar.html.erb がある（または作る）

⸻

ゴール（成果物）
	1.	Admin::Navigation（メニュー定義の単一ソース）を作成
	2.	Admin::Navigation から 現在のユーザー権限に応じて visible items を返す
	3.	サイドバー partial を Admin::Navigation ベースに置き換え
	4.	ルール：メニュー定義は view に散らさず、Navigation に集約
	5.	最低限のテスト（権限があると表示、ないと非表示）

⸻

メニュー定義仕様（重要）

メニューは階層構造を持つ
	•	親（見出し/カテゴリ）→ 子（リンク）
	•	親自体にリンクがある/ない両方に対応
	•	子が1つも表示されない親は表示しない

各アイテムは権限キーを持つ
	•	required_keys: Array
	•	表示条件は基本「required_keys の いずれかを満たす（OR）」でOK
	•	例：親カテゴリは複数キーの OR（どれか見えるならカテゴリ見える）

key は Permission seed と完全一致

例：
	•	admin.tenants.read
	•	admin.users.read
	•	admin.roles.read
	•	admin.audit_logs.read

⸻

実装要件

1) Navigation の実装（単一ソース）

ファイル例：
	•	app/models/admin/navigation.rb または app/lib/admin/navigation.rb

要件：
	•	Admin::Navigation.items が 全メニュー定義を返す
	•	Admin::Navigation.visible_items(view_context_or_controller) が
can?(key) を使って可視メニューだけ返す
	•	Rails reload に強い（定数キャッシュで壊れない）

アイテム構造（例）
	•	id（Symbol or String）
	•	label（String）
	•	path（Rails route helper name でも、固定pathでもOK）
	•	icon（任意：将来）
	•	required_keys（Array）
	•	children（Array）

Rubyの Struct / Data.define / Plain Old Ruby Object どれでもよいが、
view が読むだけで済む形にする。

⸻

2) Sidebar partial の置き換え
	•	app/views/admin/shared/_sidebar.html.erb

要件：
	•	visible_items = Admin::Navigation.visible_items(self) のように取得
	•	ループで描画
	•	active（現在ページ）判定ができるようにする（例：current_page?）
	•	子階層のインデント・見出しを最低限整える（Tailwind でOK）

⚠️ view 内に if can? を散らさない
（Navigation 側でフィルタして view は描画だけ）

⸻

3) Admin::BaseController 連携

必要なら
	•	helper_method :navigation_items を追加し
navigation_items = Admin::Navigation.visible_items(self) を返す
など、view がすっきりする形にしてよい

⸻

4) 初期メニュー内容（例）

最低限これを実装：
	•	ダッシュボード（権限なし or admin.dashboard.read を追加してもOK）
	•	テナント管理（admin.tenants.read）
	•	ユーザー管理（admin.users.read）
	•	ロール管理（admin.roles.read）
	•	監査ログ（admin.audit_logs.read）

※ Permission seed に存在する key と一致させること
※ seed に無い key を使う場合は Step2 側にも追加する（今回は追加OK）

⸻

テスト要件

RSpec 例でOK。
	•	Admin::Navigation.visible_items が
	•	can? true の items を含む
	•	can? false の items を含まない
	•	親カテゴリの children が全て false の時、親も消える

※ 権限判定はダミーの view_context を作って can? をスタブしてよい

⸻

出力形式（厳守）
	•	ファイルパス
	•	コード全文
	•	テストコード全文

コピペしてそのまま実装できる形で、必要なファイルをすべて生成してください。

⸻

重要な思想
	•	UI 出し分けは「散らさない」。Navigation を 唯一の真実にする
	•	permission.key と AuditLog.action_key と can?/authorize! が同じ文字列で揃う
	•	「見えるメニュー＝できること」を破壊しない構造にする

⸻

このプロンプトに従って Step4 を実装してください。