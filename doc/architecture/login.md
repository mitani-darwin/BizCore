あなたは **Rails 8 の業務システム（日本の中小企業向けSaaS）**を、認証・認可・マルチテナントまで破綻なく実装できるエキスパートです。
「あとから直す前提の雑実装」は禁止。最小構成でも本番に耐える土台を作ってください。

⸻

現状
	•	ログイン機能（認証）が未実装
	•	これから **管理画面（Admin）**を作りたい
	•	ただし **権限が効く（超重要）**構造にしたい
	•	マルチテナントSaaS（tenant_id 前提）

⸻

ゴール（到達点）
	1.	Devise でログインできる
	2.	current_user が使える
	3.	current_tenant を決められる（最低限でOK）
	4.	Pundit で認可できる（Policy / policy_scope が動く）
	5.	管理画面の「入口」を作り、未ログインはログインへリダイレクト
	6.	権限なしは 403 で弾ける（URL直叩き対策）
	7.	画面側でもメニュー/ボタンを権限で出し分けできる

⸻

技術前提（固定）
	•	Ruby on Rails 8
	•	View: ERB
	•	CSS: Tailwind CSS 4.1
	•	認証: Devise
	•	認可: Pundit
	•	JS: Stimulus（必要最低限）
	•	DB: 開発SQLite

⸻

必須ドメイン（最低限のテーブル）

tenants
	•	name（会社名など）
	•	（任意）slug / code

users
	•	devise 用カラム一式
	•	tenant_id（必須）
	•	name（任意）

roles / permissions（ここは最小で良い）

最初は「管理画面の保護」が目的なので、段階実装でOK。
	•	roles（tenant_id, name, key, built_in）
	•	permissions（key, description）
	•	role_permissions（role_id, permission_id）
	•	user_roles（user_id, role_id）

ただし 後で必ず拡張できる構造にすること。

⸻

マルチテナントの最低要件（重要）
	•	user は必ず tenant に所属
	•	current_tenant は「ログインユーザーの tenant」を返す最小実装でOK
	•	すべての管理画面操作は current_tenant の範囲に閉じること

⸻

実装ステップ（この順番で作って）

Step 1: Devise導入（ユーザー認証）
	•	devise を導入して User を作成
	•	ルーティング、ログイン/ログアウトが動く
	•	before_action :authenticate_user! を admin 側に適用

Step 2: Tenant導入 + current_tenant
	•	Tenant モデルを作成
	•	User に tenant_id を付ける
	•	ApplicationController に current_tenant を実装
	•	最初は current_user.tenant でOK
	•	どのクエリでも tenant を跨がないように設計（scope前提）

Step 3: Pundit導入（認可の土台）
	•	pundit 導入
	•	ApplicationController に include
	•	403 ハンドリング（権限なしの時の挙動を統一）

Step 4: Admin基盤
	•	Admin::BaseController を作り
	•	authenticate_user!
	•	pundit_user（必要なら）
	•	共通レイアウト適用
	•	/admin のダッシュボードだけ作る（まず入口）

Step 5: 「権限が効く」最小の仕組み
	•	まずは built_in role を前提に最小実装でOK
	•	例：owner だけ admin 入れる
	•	Admin::DashboardPolicy を作り
	•	index? を role/permission で判定
	•	URL直叩きで 403 になること

Step 6: Viewでの表示制御（最低限）
	•	admin sidebar に「管理」メニューを置く
	•	policy を使ってリンク表示を制御
	•	ボタン単位の制御は次フェーズ（ユーザー管理画面作成時）でOK

⸻

成果物として出力してほしいもの
	1.	必要な gems / コマンド（rails g など）
	2.	migration と model のコード
	3.	ApplicationController と Admin::BaseController
	4.	Pundit の設定（403処理含む）
	5.	最小の Policy（Admin Dashboard 用）
	6.	最小の admin レイアウト（ERB + Tailwind）
	7.	動作確認手順（rails s して何を踏めばいいか）

⸻

厳守事項（事故防止）
	•	管理画面は必ずログイン必須
	•	権限なしは必ず 403（画面非表示だけで済ませない）
	•	policy_scope を使う設計を前提にする（後から困らない）
	•	tenant を跨ぐ可能性があるクエリは禁止

⸻

ここから実装を開始してください

「Step 1 から順に」、必要ファイルを パス付きで提示しながら進めてください。